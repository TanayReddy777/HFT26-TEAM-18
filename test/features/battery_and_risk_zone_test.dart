import 'package:flutter_test/flutter_test.dart';
import 'package:resq/core/models/location_snapshot.dart';
import 'package:resq/core/models/power_state.dart';
import 'package:resq/core/models/risk_zone.dart';
import 'package:resq/core/storage/local_database.dart';
import 'package:resq/features/power_safety/risk_zone_evaluator.dart';

void main() {
  group('Battery Bands & Offline Risk Zone Tests', () {
    test('Calculates nonoverlapping battery bands accurately', () {
      expect(PowerState.calculateBand(85.0), equals(PowerBand.normal));
      expect(PowerState.calculateBand(25.0), equals(PowerBand.powerOptimization));
      expect(PowerState.calculateBand(12.0), equals(PowerBand.lowPowerPreparation));
      expect(PowerState.calculateBand(8.0), equals(PowerBand.lowPowerAlert));
      expect(PowerState.calculateBand(3.0), equals(PowerBand.criticalPower));
    });

    test('RiskZoneEvaluator identifies location inside RED hazard zone', () async {
      final db = LocalDatabase();
      await db.saveRiskZone(const RiskZone(
        id: 'ZONE_RED_TEST',
        name: 'Flashflood Zone',
        centerLatitude: 16.5000,
        centerLongitude: 80.6000,
        radiusMeters: 500.0,
        riskLevel: RiskLevel.red,
        description: 'Dangerous surge',
        sourceProvenance: 'Offline Survey',
      ));

      final evaluator = RiskZoneEvaluator(database: db);

      // Point located 100m away from zone center (well inside 500m radius)
      final userFix = LocationSnapshot(
        latitude: 16.5005,
        longitude: 80.6000,
        accuracyMeters: 10.0,
        recordedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final res = evaluator.evaluateLocation(userFix);
      expect(res.effectiveRiskLevel, equals(RiskLevel.red));
      expect(res.isReliablyInRedZone, isTrue);
    });
  });
}
