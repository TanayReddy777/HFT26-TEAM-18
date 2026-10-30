import 'dart:async';
import '../../core/contracts/power_policy_provider.dart';
import '../../core/models/power_state.dart';

class FakeBatteryProvider implements PowerPolicyProvider {
  PowerState _powerState = PowerState(
    percentage: 100.0,
    isCharging: false,
    isBatterySaverOn: false,
    band: PowerBand.normal,
    lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
  );

  final _controller = StreamController<PowerState>.broadcast();

  @override
  PowerState get currentPowerState => _powerState;

  @override
  PowerPolicy get currentPolicy => _powerState.toPolicy();

  @override
  Stream<PowerState> get powerStateStream => _controller.stream;

  void setBattery(double percentage, {bool isCharging = false}) {
    _powerState = PowerState(
      percentage: percentage,
      isCharging: isCharging,
      isBatterySaverOn: percentage <= 30.0,
      band: PowerState.calculateBand(percentage),
      lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    _controller.add(_powerState);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> shutdown() async {}
}
