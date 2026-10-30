import '../models/power_state.dart';

abstract class PowerPolicyProvider {
  PowerState get currentPowerState;
  PowerPolicy get currentPolicy;
  Stream<PowerState> get powerStateStream;

  Future<void> initialize();
  Future<void> shutdown();
}
