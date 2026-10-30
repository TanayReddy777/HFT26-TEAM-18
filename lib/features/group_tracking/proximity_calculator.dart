import '../../core/location/haversine.dart';
import '../../core/models/location_snapshot.dart';
import '../../core/models/member.dart';

class ProximityStatus {
  final String memberId;
  final String memberName;
  final SeparationAssessment assessment;
  final int lastUpdateAgeSeconds;
  final bool isStale;

  const ProximityStatus({
    required this.memberId,
    required this.memberName,
    required this.assessment,
    required this.lastUpdateAgeSeconds,
    required this.isStale,
  });
}

class ProximityCalculator {
  double warningDistance;
  double criticalDistance;
  final int maxFreshnessSeconds;

  ProximityCalculator({
    this.warningDistance = 50.0,
    this.criticalDistance = 100.0,
    this.maxFreshnessSeconds = 60,
  }) {
    assert(warningDistance > 0 && warningDistance < criticalDistance,
        'Thresholds must satisfy 0 < warning < critical');
  }

  void updateThresholds(double warning, double critical) {
    if (warning > 0 && warning < critical) {
      warningDistance = warning;
      criticalDistance = critical;
    }
  }

  ProximityStatus evaluatePeerProximity({
    required LocationSnapshot? ownFix,
    required Member peer,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final fixTime = peer.lastFixEpochMs ?? peer.lastSeenEpochMs;
    final ageSeconds = ((now - fixTime) / 1000).round();
    final isStale = ageSeconds > maxFreshnessSeconds;

    if (ownFix == null || peer.lastLatitude == null || peer.lastLongitude == null) {
      return ProximityStatus(
        memberId: peer.id,
        memberName: peer.displayName,
        assessment: const SeparationAssessment(
          state: SeparationState.locationUnavailable,
          description: 'Peer coordinates unavailable',
        ),
        lastUpdateAgeSeconds: ageSeconds,
        isStale: isStale,
      );
    }

    if (isStale) {
      return ProximityStatus(
        memberId: peer.id,
        memberName: peer.displayName,
        assessment: const SeparationAssessment(
          state: SeparationState.locationUnavailable,
          description: 'Peer location is stale (>60s ago)',
        ),
        lastUpdateAgeSeconds: ageSeconds,
        isStale: true,
      );
    }

    final assessment = Haversine.assessSeparation(
      lat1: ownFix.latitude,
      lon1: ownFix.longitude,
      accuracy1: ownFix.accuracyMeters,
      lat2: peer.lastLatitude,
      lon2: peer.lastLongitude,
      accuracy2: peer.lastAccuracyMeters,
      warningDistance: warningDistance,
      criticalDistance: criticalDistance,
    );

    return ProximityStatus(
      memberId: peer.id,
      memberName: peer.displayName,
      assessment: assessment,
      lastUpdateAgeSeconds: ageSeconds,
      isStale: false,
    );
  }
}
