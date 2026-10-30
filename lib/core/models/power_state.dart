enum PowerBand {
  normal, // > 30%
  powerOptimization, // 15% <= b <= 30%
  lowPowerPreparation, // 10% <= b < 15%
  lowPowerAlert, // 5% <= b < 10%
  criticalPower, // < 5%
  unknown,
}

enum PowerPolicyLevel {
  normal,
  lowPower,
  criticalPower,
}

class PowerPolicy {
  final PowerPolicyLevel level;
  final int locationIntervalSeconds;
  final int discoveryDutyCycleSeconds;
  final bool allowNonEssentialNLP;
  final bool allowBackgroundSync;

  const PowerPolicy({
    required this.level,
    required this.locationIntervalSeconds,
    required this.discoveryDutyCycleSeconds,
    required this.allowNonEssentialNLP,
    required this.allowBackgroundSync,
  });

  static const normal = PowerPolicy(
    level: PowerPolicyLevel.normal,
    locationIntervalSeconds: 10,
    discoveryDutyCycleSeconds: 15,
    allowNonEssentialNLP: true,
    allowBackgroundSync: true,
  );

  static const lowPower = PowerPolicy(
    level: PowerPolicyLevel.lowPower,
    locationIntervalSeconds: 30,
    discoveryDutyCycleSeconds: 45,
    allowNonEssentialNLP: false,
    allowBackgroundSync: false,
  );

  static const criticalPower = PowerPolicy(
    level: PowerPolicyLevel.criticalPower,
    locationIntervalSeconds: 90,
    discoveryDutyCycleSeconds: 120,
    allowNonEssentialNLP: false,
    allowBackgroundSync: false,
  );
}

class PowerState {
  final double percentage; // 0.0 - 100.0
  final bool isCharging;
  final bool isBatterySaverOn;
  final PowerBand band;
  final int lastUpdatedEpochMs;

  const PowerState({
    required this.percentage,
    required this.isCharging,
    required this.isBatterySaverOn,
    required this.band,
    required this.lastUpdatedEpochMs,
  });

  static PowerBand calculateBand(double percentage) {
    if (percentage > 30.0) return PowerBand.normal;
    if (percentage >= 15.0) return PowerBand.powerOptimization;
    if (percentage >= 10.0) return PowerBand.lowPowerPreparation;
    if (percentage >= 5.0) return PowerBand.lowPowerAlert;
    if (percentage >= 0.0) return PowerBand.criticalPower;
    return PowerBand.unknown;
  }

  PowerPolicy toPolicy() {
    if (band == PowerBand.criticalPower) return PowerPolicy.criticalPower;
    if (band == PowerBand.lowPowerAlert ||
        band == PowerBand.lowPowerPreparation ||
        band == PowerBand.powerOptimization) {
      return PowerPolicy.lowPower;
    }
    return PowerPolicy.normal;
  }
}
