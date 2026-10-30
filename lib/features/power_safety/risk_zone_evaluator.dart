import '../../core/location/haversine.dart';
import '../../core/models/location_snapshot.dart';
import '../../core/models/risk_zone.dart';
import '../../core/storage/local_database.dart';

class ZoneEvaluationResult {
  final RiskZone? activeZone;
  final RiskLevel effectiveRiskLevel;
  final bool isReliablyInRedZone;
  final double? distanceToCenter;
  final String description;

  const ZoneEvaluationResult({
    this.activeZone,
    required this.effectiveRiskLevel,
    required this.isReliablyInRedZone,
    this.distanceToCenter,
    required this.description,
  });
}

class RiskZoneEvaluator {
  final LocalDatabase database;

  RiskZoneEvaluator({required this.database});

  ZoneEvaluationResult evaluateLocation(LocationSnapshot? location) {
    if (location == null) {
      return const ZoneEvaluationResult(
        effectiveRiskLevel: RiskLevel.unknown,
        isReliablyInRedZone: false,
        description: 'Location unavailable: risk zone indeterminate',
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final zones = database.getAllRiskZones().where((z) => !z.isExpired(now)).toList();

    for (final zone in zones) {
      final dist = Haversine.calculateDistance(
        location.latitude,
        location.longitude,
        zone.centerLatitude,
        zone.centerLongitude,
      );

      // Total uncertainty from GPS accuracy
      final minDistance = dist - location.accuracyMeters;
      final maxDistance = dist + location.accuracyMeters;

      // Inside zone boundary check
      if (dist <= zone.radiusMeters) {
        // Reliably inside RED zone if maxDistance is also within radius,
        // or conservative boundary check
        final isReliable = maxDistance <= (zone.radiusMeters * 1.1);

        return ZoneEvaluationResult(
          activeZone: zone,
          effectiveRiskLevel: zone.riskLevel,
          isReliablyInRedZone: zone.riskLevel == RiskLevel.red && isReliable,
          distanceToCenter: dist,
          description: '${zone.riskLevel.name.toUpperCase()} Zone: ${zone.name} (${zone.description})',
        );
      }
    }

    return const ZoneEvaluationResult(
      effectiveRiskLevel: RiskLevel.green,
      isReliablyInRedZone: false,
      description: 'Clear: Outside defined hazard zones',
    );
  }
}
