import 'dart:math';

enum SeparationState {
  withinRange,
  warningSeparation,
  criticalSeparation,
  distanceUncertain,
  locationUnavailable,
}

class SeparationAssessment {
  final double? distanceMeters;
  final double? minDistanceMeters;
  final double? maxDistanceMeters;
  final SeparationState state;
  final String description;

  const SeparationAssessment({
    this.distanceMeters,
    this.minDistanceMeters,
    this.maxDistanceMeters,
    required this.state,
    required this.description,
  });
}

class Haversine {
  static const double earthRadiusMeters = 6371000.0;

  static double _toRadians(double degrees) => degrees * pi / 180.0;
  static double _toDegrees(double radians) => radians * 180.0 / pi;

  /// Calculates geodesic distance between two coordinates in meters
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Calculates initial geographic bearing from point 1 to point 2 in degrees (0..360)
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final deltaLambda = _toRadians(lon2 - lon1);

    final y = sin(deltaLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);

    final theta = atan2(y, x);
    final bearing = (_toDegrees(theta) + 360.0) % 360.0;
    return bearing;
  }

  /// Evaluates separation state considering conservative horizontal accuracy bounds
  static SeparationAssessment assessSeparation({
    required double? lat1,
    required double? lon1,
    required double? accuracy1,
    required double? lat2,
    required double? lon2,
    required double? accuracy2,
    double warningDistance = 50.0,
    double criticalDistance = 100.0,
  }) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
      return const SeparationAssessment(
        state: SeparationState.locationUnavailable,
        description: 'Location unavailable for one or both peers',
      );
    }

    final distance = calculateDistance(lat1, lon1, lat2, lon2);
    final totalUncertainty = (accuracy1 ?? 0.0) + (accuracy2 ?? 0.0);
    final minDistance = max(0.0, distance - totalUncertainty);
    final maxDistance = distance + totalUncertainty;

    // Conservative heuristic: if uncertainty span crosses warning or critical thresholds,
    // classify as distance uncertain rather than false confidence
    final crossesWarning = minDistance < warningDistance && maxDistance >= warningDistance;
    final crossesCritical = minDistance < criticalDistance && maxDistance >= criticalDistance;

    if (crossesWarning || crossesCritical) {
      return SeparationAssessment(
        distanceMeters: distance,
        minDistanceMeters: minDistance,
        maxDistanceMeters: maxDistance,
        state: SeparationState.distanceUncertain,
        description: 'Distance estimated at ${distance.toStringAsFixed(1)}m ±${totalUncertainty.toStringAsFixed(1)}m (Uncertain)',
      );
    }

    if (distance >= criticalDistance) {
      return SeparationAssessment(
        distanceMeters: distance,
        minDistanceMeters: minDistance,
        maxDistanceMeters: maxDistance,
        state: SeparationState.criticalSeparation,
        description: 'Critical separation: ${distance.toStringAsFixed(1)}m',
      );
    }

    if (distance >= warningDistance) {
      return SeparationAssessment(
        distanceMeters: distance,
        minDistanceMeters: minDistance,
        maxDistanceMeters: maxDistance,
        state: SeparationState.warningSeparation,
        description: 'Warning separation: ${distance.toStringAsFixed(1)}m',
      );
    }

    return SeparationAssessment(
      distanceMeters: distance,
      minDistanceMeters: minDistance,
      maxDistanceMeters: maxDistance,
      state: SeparationState.withinRange,
      description: 'Within configured range: ${distance.toStringAsFixed(1)}m',
    );
  }
}
