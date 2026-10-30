import 'package:flutter_test/flutter_test.dart';
import 'package:resq/core/location/haversine.dart';

void main() {
  group('Haversine & Separation Tests', () {
    test('Calculates distance accurately between coordinates', () {
      final distance = Haversine.calculateDistance(0.0, 0.0, 1.0, 0.0);
      expect(distance, greaterThan(110000.0));
      expect(distance, lessThan(112000.0));
    });

    test('Calculates bearing due East as 90 degrees', () {
      final bearing = Haversine.calculateBearing(0.0, 0.0, 0.0, 1.0);
      expect((bearing - 90.0).abs(), lessThan(0.5));
    });

    test('Detects distance uncertainty when error span crosses warning threshold', () {
      // Distance is 55m, total uncertainty is 20m + 20m = 40m. Span is [15m, 95m], crossing 50m warning.
      final assessment = Haversine.assessSeparation(
        lat1: 16.5000,
        lon1: 80.6000,
        accuracy1: 20.0,
        lat2: 16.5005,
        lon2: 80.6000,
        accuracy2: 20.0,
        warningDistance: 50.0,
        criticalDistance: 100.0,
      );

      expect(assessment.state, equals(SeparationState.distanceUncertain));
    });

    test('Identifies within range safely when completely under threshold', () {
      final assessment = Haversine.assessSeparation(
        lat1: 16.5000,
        lon1: 80.6000,
        accuracy1: 2.0,
        lat2: 16.5001,
        lon2: 80.6000,
        accuracy2: 2.0,
        warningDistance: 50.0,
        criticalDistance: 100.0,
      );

      expect(assessment.state, equals(SeparationState.withinRange));
    });
  });
}
