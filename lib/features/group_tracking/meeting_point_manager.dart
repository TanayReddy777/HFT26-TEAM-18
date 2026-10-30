import 'dart:async';
import '../../core/contracts/meeting_point_repository.dart';
import '../../core/location/haversine.dart';
import '../../core/models/meeting_point.dart';
import '../../core/models/receipt.dart';
import '../../core/storage/local_database.dart';

class MeetingPointGuidance {
  final double distanceMeters;
  final double bearingDegrees;
  final String cardinalDirection;
  final int revision;
  final String disclaimer;
  final bool isNearDestination;

  const MeetingPointGuidance({
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.cardinalDirection,
    required this.revision,
    this.disclaimer = 'Straight-line direction; obstacles and terrain not considered.',
    required this.isNearDestination,
  });
}

class MeetingPointManager implements MeetingPointRepository {
  final LocalDatabase database;
  final String localNodeId;
  final bool Function() isLeaderCheck;

  MeetingPointManager({
    required this.database,
    required this.localNodeId,
    required this.isLeaderCheck,
  });

  @override
  MeetingPointUpdate? get currentMeetingPoint => database.currentMeetingPoint;

  @override
  Stream<MeetingPointUpdate?> get meetingPointStream => database.meetingPointStream;

  @override
  List<Receipt> get receipts => database.getReceiptsFor(
        currentMeetingPoint?.pointId ?? '',
        currentMeetingPoint?.sessionRevision ?? 0,
      );

  @override
  Future<void> saveMeetingPoint(MeetingPointUpdate update) async {
    // Only accepted if sender has leader authority or receiving a valid newer revision
    await database.saveMeetingPoint(update);
  }

  Future<MeetingPointUpdate?> createOrUpdateMeetingPoint({
    required String name,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    double suggestedRadius = 100.0,
  }) async {
    if (!isLeaderCheck()) {
      throw StateError('Unauthorized: Only the designated session leader can create or update meeting points.');
    }

    final current = currentMeetingPoint;
    final nextRevision = (current?.sessionRevision ?? 0) + 1;
    final pointId = current?.pointId ?? 'POINT_${DateTime.now().millisecondsSinceEpoch}';

    final update = MeetingPointUpdate(
      pointId: pointId,
      sessionRevision: nextRevision,
      action: MeetingPointAction.upsert,
      creatorId: current?.creatorId ?? localNodeId,
      updatedBy: localNodeId,
      createdAt: current?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      name: name,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      suggestedBoundaryRadiusMeters: suggestedRadius,
    );

    await database.saveMeetingPoint(update);
    return update;
  }

  @override
  Future<void> removeMeetingPoint(String pointId, int newRevision, String updatedBy) async {
    final tombstone = MeetingPointUpdate(
      pointId: pointId,
      sessionRevision: newRevision,
      action: MeetingPointAction.remove,
      creatorId: currentMeetingPoint?.creatorId ?? localNodeId,
      updatedBy: updatedBy,
      createdAt: currentMeetingPoint?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await database.saveMeetingPoint(tombstone);
  }

  @override
  Future<void> recordReceipt(Receipt receipt) async {
    await database.recordReceipt(receipt);
  }

  @override
  int getReceiptCountForRevision(int revision) {
    if (currentMeetingPoint == null) return 0;
    return database.getReceiptsFor(currentMeetingPoint!.pointId, revision).length;
  }

  MeetingPointGuidance? calculateGuidance(double? ownLat, double? ownLon) {
    final point = currentMeetingPoint;
    if (point == null || point.isRemoval || ownLat == null || ownLon == null) {
      return null;
    }

    final dist = Haversine.calculateDistance(ownLat, ownLon, point.latitude!, point.longitude!);
    final bearing = Haversine.calculateBearing(ownLat, ownLon, point.latitude!, point.longitude!);

    return MeetingPointGuidance(
      distanceMeters: dist,
      bearingDegrees: bearing,
      cardinalDirection: _bearingToCardinal(bearing),
      revision: point.sessionRevision,
      isNearDestination: dist <= (point.suggestedBoundaryRadiusMeters ?? 100.0) / 2,
    );
  }

  String _bearingToCardinal(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) % 360 / 45).floor();
    return directions[index];
  }
}
