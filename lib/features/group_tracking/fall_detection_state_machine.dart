import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/constants/event_codes.dart';
import '../../core/constants/priorities.dart';
import '../../core/contracts/motion_provider.dart';
import '../../core/contracts/safety_check_coordinator.dart';
import '../../core/contracts/incident_service.dart';
import '../../core/models/incident_snapshot.dart';

enum FallDetectionPhase {
  monitoring,
  freeFallDetected,
  impactDetected,
  postImpactStillness,
  fallTriggered,
}

class FallDetectionStateMachine {
  final SafetyCheckCoordinator safetyCoordinator;
  final IncidentService incidentService;
  final String localUserId;

  bool isEnabled = true;
  FallDetectionPhase _phase = FallDetectionPhase.monitoring;
  int _phaseStartTimeEpochMs = 0;

  // Detection thresholds
  final double freeFallThresholdG; // < 0.5G indicates potential drop/free-fall
  final double impactThresholdG; // > 2.5G indicates sharp impact
  final double stillnessThresholdG; // ~ 1.0G (0.85 - 1.15G) indicates lack of user movement
  final int stillnessWindowMs; // 2500ms required stillness

  String? _activeFallIncidentId;

  FallDetectionStateMachine({
    required this.safetyCoordinator,
    required this.incidentService,
    required this.localUserId,
    this.freeFallThresholdG = 0.5,
    this.impactThresholdG = 2.5,
    this.stillnessThresholdG = 0.25, // Deviation from 1G
    this.stillnessWindowMs = 2500,
  });

  FallDetectionPhase get currentPhase => _phase;

  void processMotionEvent(MotionEvent event) {
    if (!isEnabled) return;

    final now = event.timestampEpochMs;
    final totalG = event.totalG;

    switch (_phase) {
      case FallDetectionPhase.monitoring:
        if (totalG < freeFallThresholdG) {
          _phase = FallDetectionPhase.freeFallDetected;
          _phaseStartTimeEpochMs = now;
        } else if (totalG > impactThresholdG) {
          // Direct sudden impact without extended freefall
          _phase = FallDetectionPhase.impactDetected;
          _phaseStartTimeEpochMs = now;
        }
        break;

      case FallDetectionPhase.freeFallDetected:
        if (totalG > impactThresholdG) {
          _phase = FallDetectionPhase.impactDetected;
          _phaseStartTimeEpochMs = now;
        } else if (now - _phaseStartTimeEpochMs > 1000) {
          // Free fall timed out without impact (e.g. phone tossed gently or elevator)
          _phase = FallDetectionPhase.monitoring;
        }
        break;

      case FallDetectionPhase.impactDetected:
        final deviation = (totalG - 1.0).abs();
        if (deviation < stillnessThresholdG) {
          _phase = FallDetectionPhase.postImpactStillness;
          _phaseStartTimeEpochMs = now;
        } else if (now - _phaseStartTimeEpochMs > 1500) {
          // Still vigorous motion after impact -> phone picked up immediately or jogging
          _phase = FallDetectionPhase.monitoring;
        }
        break;

      case FallDetectionPhase.postImpactStillness:
        final dev = (totalG - 1.0).abs();
        if (dev > stillnessThresholdG * 2.0) {
          // User resumed movement -> self recovered
          _phase = FallDetectionPhase.monitoring;
        } else if (now - _phaseStartTimeEpochMs >= stillnessWindowMs) {
          // Sustained post-impact stillness confirmed -> trigger experimental fall alert
          _phase = FallDetectionPhase.fallTriggered;
          _triggerFallAlert();
        }
        break;

      case FallDetectionPhase.fallTriggered:
        // Wait until alert is resolved or reset
        break;
    }
  }

  Future<void> _triggerFallAlert() async {
    _activeFallIncidentId = const Uuid().v4();

    // 1. Submit initial revision 1 as POSSIBLE_FALL / UNCONFIRMED
    final incident = await incidentService.submitIncident(
      sourceModule: 'FallDetectionStateMachine',
      eventCode: EventCodes.possibleFall,
      severity: Priority.p1Urgent,
      explicitSos: false,
      reason: 'Experimental sensor impact & stillness detected possible fall',
    );

    // 2. Prompt local user: "Possible fall detected. Are you okay?"
    final check = SafetyCheckRequest(
      id: 'FALL_CHECK_${incident.incidentId}',
      trigger: SafetyCheckTrigger.possibleFall,
      reason: 'Possible fall detected. Are you okay?',
      priority: Priority.p0Critical,
      deadlineEpochMs: DateTime.now().millisecondsSinceEpoch + 30000, // 30s countdown
      allowsSnooze: false,
    );

    await safetyCoordinator.requestSafetyCheck(check);
  }

  void reset() {
    _phase = FallDetectionPhase.monitoring;
    _activeFallIncidentId = null;
  }
}
