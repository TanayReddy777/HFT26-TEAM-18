import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import '../../core/constants/event_codes.dart';
import '../../core/constants/priorities.dart';
import '../../core/contracts/incident_service.dart';
import '../../core/contracts/location_provider.dart';
import '../../core/contracts/power_policy_provider.dart';
import '../../core/contracts/safety_check_coordinator.dart';
import '../../core/models/power_state.dart';
import 'risk_zone_evaluator.dart';

class BatteryMonitor implements PowerPolicyProvider {
  final Battery _battery = Battery();
  final IncidentService incidentService;
  final LocationProvider locationProvider;
  final SafetyCheckCoordinator safetyCoordinator;
  final RiskZoneEvaluator riskZoneEvaluator;

  PowerState _currentPowerState = PowerState(
    percentage: 100.0,
    isCharging: false,
    isBatterySaverOn: false,
    band: PowerBand.normal,
    lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
  );

  // Episode latches to prevent duplicate submissions
  bool _emittedLowPowerAlertForEpisode = false;
  bool _emittedCriticalPowerForEpisode = false;

  final _powerStateController = StreamController<PowerState>.broadcast();
  StreamSubscription<BatteryState>? _batteryStateSub;

  BatteryMonitor({
    required this.incidentService,
    required this.locationProvider,
    required this.safetyCoordinator,
    required this.riskZoneEvaluator,
  });

  @override
  PowerState get currentPowerState => _currentPowerState;

  @override
  PowerPolicy get currentPolicy => _currentPowerState.toPolicy();

  @override
  Stream<PowerState> get powerStateStream => _powerStateController.stream;

  @override
  Future<void> initialize() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      _updateBatteryState(level.toDouble(), state == BatteryState.charging);

      _batteryStateSub = _battery.onBatteryStateChanged.listen((state) async {
        final lvl = await _battery.batteryLevel;
        _updateBatteryState(lvl.toDouble(), state == BatteryState.charging);
      });
    } catch (_) {
      // Safe fallback for test/simulator environments
    }
  }

  void injectBatteryLevelForTesting(double percentage, bool isCharging) {
    _updateBatteryState(percentage, isCharging);
  }

  void _updateBatteryState(double percentage, bool isCharging) {
    final prevPercentage = _currentPowerState.percentage;
    final band = PowerState.calculateBand(percentage);

    _currentPowerState = PowerState(
      percentage: percentage,
      isCharging: isCharging,
      isBatterySaverOn: band != PowerBand.normal,
      band: band,
      lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    _powerStateController.add(_currentPowerState);

    // Hysteresis reset: if charged above 20%, reset latches for the next discharge cycle
    if (percentage >= 20.0 && isCharging) {
      _emittedLowPowerAlertForEpisode = false;
      _emittedCriticalPowerForEpisode = false;
    }

    _evaluateThresholdCrossings(prevPercentage, percentage);
  }

  Future<void> _evaluateThresholdCrossings(double prev, double current) async {
    final fix = locationProvider.latestFix;
    final zoneResult = riskZoneEvaluator.evaluateLocation(fix);

    // 1. Transition crossing into <10% (LOW_POWER_ALERT)
    if (current < 10.0 && !_emittedLowPowerAlertForEpisode) {
      _emittedLowPowerAlertForEpisode = true;

      await incidentService.submitIncident(
        sourceModule: 'BatteryMonitor',
        eventCode: EventCodes.lowPowerAlert,
        severity: Priority.p2Warning,
        explicitSos: false,
        reason: 'Battery level reached ${current.toStringAsFixed(0)}% (Discharge episode)',
      );

      // Low battery in a verified RED zone triggers a mandatory shared safety check
      if (zoneResult.isReliablyInRedZone) {
        final check = SafetyCheckRequest(
          id: 'CHECK_LOW_BATTERY_RED_ZONE_${DateTime.now().millisecondsSinceEpoch}',
          trigger: SafetyCheckTrigger.lowPowerInRedZone,
          reason: 'Low battery (${current.toStringAsFixed(0)}%) within RED hazard zone (${zoneResult.activeZone?.name}). Are you safe?',
          priority: Priority.p1Urgent,
          deadlineEpochMs: DateTime.now().millisecondsSinceEpoch + 60000, // 60s
          allowsSnooze: true,
        );
        await safetyCoordinator.requestSafetyCheck(check);
      }
    }

    // 2. Transition crossing into <5% (CRITICAL_LOW_POWER)
    if (current < 5.0 && !_emittedCriticalPowerForEpisode) {
      _emittedCriticalPowerForEpisode = true;

      await incidentService.submitIncident(
        sourceModule: 'BatteryMonitor',
        eventCode: EventCodes.criticalLowPower,
        severity: Priority.p2Warning,
        explicitSos: false,
        reason: 'Critical battery level: ${current.toStringAsFixed(0)}%',
      );
    }
  }

  @override
  Future<void> shutdown() async {
    await _batteryStateSub?.cancel();
  }
}
