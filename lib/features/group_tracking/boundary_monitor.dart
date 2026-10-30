import '../../core/location/haversine.dart';
import '../../core/models/meeting_point.dart';

enum BoundaryState {
  inside,
  outside,
  uncertain,
  unavailable,
  alertsDisabled,
}

class BoundaryObservation {
  final BoundaryState state;
  final double? distanceMeters;
  final double? boundaryRadiusMeters;
  final bool isExitTriggered;
  final String statusMessage;

  const BoundaryObservation({
    required this.state,
    this.distanceMeters,
    this.boundaryRadiusMeters,
    this.isExitTriggered = false,
    required this.statusMessage,
  });
}

class BoundaryMonitor {
  bool alertsEnabled = true;
  BoundaryState _lastConfirmedState = BoundaryState.unavailable;
  int _consecutiveOutsideCount = 0;
  static const int requiredDwellCount = 2; // Hysteresis dwell

  void setAlertsEnabled(bool enabled) {
    alertsEnabled = enabled;
  }

  BoundaryObservation evaluate({
    required double? ownLat,
    required double? ownLon,
    required double? ownAccuracy,
    required MeetingPointUpdate? meetingPoint,
  }) {
    if (!alertsEnabled) {
      return const BoundaryObservation(
        state: BoundaryState.alertsDisabled,
        statusMessage: 'Boundary alerts disabled by user',
      );
    }

    if (meetingPoint == null ||
        meetingPoint.isRemoval ||
        meetingPoint.latitude == null ||
        meetingPoint.longitude == null ||
        ownLat == null ||
        ownLon == null) {
      _lastConfirmedState = BoundaryState.unavailable;
      return const BoundaryObservation(
        state: BoundaryState.unavailable,
        statusMessage: 'Meeting point or current GPS coordinates unavailable',
      );
    }

    final radius = meetingPoint.suggestedBoundaryRadiusMeters ?? 100.0;
    final distance = Haversine.calculateDistance(
      ownLat,
      ownLon,
      meetingPoint.latitude!,
      meetingPoint.longitude!,
    );

    final totalUncertainty = (ownAccuracy ?? 0.0) + (meetingPoint.accuracyMeters ?? 0.0);
    final minDistance = distance - totalUncertainty;
    final maxDistance = distance + totalUncertainty;

    // Check if uncertainty span crosses boundary radius
    if (minDistance < radius && maxDistance >= radius) {
      return BoundaryObservation(
        state: BoundaryState.uncertain,
        distanceMeters: distance,
        boundaryRadiusMeters: radius,
        statusMessage: 'Boundary distance uncertain (${distance.toStringAsFixed(1)}m ±${totalUncertainty.toStringAsFixed(1)}m)',
      );
    }

    if (distance > radius) {
      _consecutiveOutsideCount++;
      final isNewExit = (_lastConfirmedState == BoundaryState.inside) &&
          (_consecutiveOutsideCount >= requiredDwellCount);

      if (_consecutiveOutsideCount >= requiredDwellCount) {
        _lastConfirmedState = BoundaryState.outside;
      }

      return BoundaryObservation(
        state: BoundaryState.outside,
        distanceMeters: distance,
        boundaryRadiusMeters: radius,
        isExitTriggered: isNewExit,
        statusMessage: 'Outside boundary: ${distance.toStringAsFixed(1)}m (Limit: ${radius.toStringAsFixed(1)}m)',
      );
    } else {
      _consecutiveOutsideCount = 0;
      _lastConfirmedState = BoundaryState.inside;
      return BoundaryObservation(
        state: BoundaryState.inside,
        distanceMeters: distance,
        boundaryRadiusMeters: radius,
        statusMessage: 'Inside safe meeting boundary (${distance.toStringAsFixed(1)}m)',
      );
    }
  }
}
