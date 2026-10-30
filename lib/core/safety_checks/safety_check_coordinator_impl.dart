import 'dart:async';
import '../contracts/safety_check_coordinator.dart';
import '../contracts/incident_service.dart';
import '../constants/event_codes.dart';
import '../constants/priorities.dart';

class SafetyCheckCoordinatorImpl implements SafetyCheckCoordinator {
  final IncidentService incidentService;
  SafetyCheckRequest? _currentActiveCheck;
  Timer? _deadlineTimer;

  final _checkStreamController = StreamController<SafetyCheckRequest?>.broadcast();
  final Map<String, Completer<SafetyCheckResponse>> _pendingCompleters = {};

  SafetyCheckCoordinatorImpl({required this.incidentService});

  @override
  SafetyCheckRequest? get currentActiveCheck => _currentActiveCheck;

  @override
  Stream<SafetyCheckRequest?> get activeCheckStream => _checkStreamController.stream;

  @override
  Future<void> requestSafetyCheck(SafetyCheckRequest request) async {
    // If an existing check is active, arbitrate based on priority
    if (_currentActiveCheck != null) {
      if (request.priority > _currentActiveCheck!.priority) {
        // Lower priority incoming check is queued or dropped
        return;
      }
      // Incoming check is equal or higher priority: cancel current and replace
      _cancelInternalTimer();
    }

    _currentActiveCheck = request;
    _checkStreamController.add(request);

    final remainingMs = request.deadlineEpochMs - DateTime.now().millisecondsSinceEpoch;
    final waitDuration = remainingMs > 0 ? Duration(milliseconds: remainingMs) : const Duration(seconds: 30);

    _deadlineTimer = Timer(waitDuration, () {
      respondToCheck(request.id, SafetyCheckResponse.timeout);
    });
  }

  @override
  Future<void> respondToCheck(String checkId, SafetyCheckResponse response) async {
    if (_currentActiveCheck?.id != checkId) return;

    _cancelInternalTimer();
    final request = _currentActiveCheck!;
    _currentActiveCheck = null;
    _checkStreamController.add(null);

    switch (response) {
      case SafetyCheckResponse.iAmSafe:
        // Update any active unconfirmed incident to Safe
        await incidentService.submitIncident(
          sourceModule: 'SafetyCheckCoordinator',
          eventCode: EventCodes.userConfirmedSafe,
          severity: Priority.p3Normal,
          explicitSos: false,
          reason: 'User explicitly confirmed safe in response to ${request.reason}',
        );
        break;

      case SafetyCheckResponse.needHelp:
        // User requested immediate help -> Escalate to P0 explicit SOS
        await incidentService.submitIncident(
          sourceModule: 'SafetyCheckCoordinator',
          eventCode: EventCodes.confirmedSos,
          severity: Priority.p0Critical,
          explicitSos: true,
          reason: 'User pressed NEED HELP during check: ${request.reason}',
        );
        break;

      case SafetyCheckResponse.timeout:
        // Non-response deadline reached -> Escalate to UNCONFIRMED_SOS
        await incidentService.submitIncident(
          sourceModule: 'SafetyCheckCoordinator',
          eventCode: request.trigger == SafetyCheckTrigger.contactLoss
              ? EventCodes.contactCheckUnanswered
              : EventCodes.unconfirmedSos,
          severity: Priority.p1Urgent,
          explicitSos: false,
          reason: 'Safety check timed out without user response: ${request.reason}',
        );
        break;

      case SafetyCheckResponse.snooze:
        // Bounded snooze preserves pending status
        break;
    }
  }

  @override
  Future<void> snoozeCheck(String checkId, int snoozeDurationSeconds) async {
    if (_currentActiveCheck?.id != checkId || !_currentActiveCheck!.allowsSnooze) return;

    _cancelInternalTimer();
    final updatedDeadline = DateTime.now().millisecondsSinceEpoch + (snoozeDurationSeconds * 1000);
    final snoozedRequest = SafetyCheckRequest(
      id: _currentActiveCheck!.id,
      trigger: _currentActiveCheck!.trigger,
      reason: '${_currentActiveCheck!.reason} (Snoozed)',
      priority: _currentActiveCheck!.priority,
      deadlineEpochMs: updatedDeadline,
      allowsSnooze: false, // Disallow chained endless snoozing
    );

    _currentActiveCheck = snoozedRequest;
    _checkStreamController.add(snoozedRequest);

    _deadlineTimer = Timer(Duration(seconds: snoozeDurationSeconds), () {
      respondToCheck(snoozedRequest.id, SafetyCheckResponse.timeout);
    });
  }

  @override
  Future<void> cancelCheck(String checkId) async {
    if (_currentActiveCheck?.id == checkId) {
      _cancelInternalTimer();
      _currentActiveCheck = null;
      _checkStreamController.add(null);
    }
  }

  void _cancelInternalTimer() {
    _deadlineTimer?.cancel();
    _deadlineTimer = null;
  }
}
