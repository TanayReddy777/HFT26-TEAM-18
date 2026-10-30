enum MeetingPointAction {
  upsert,
  remove,
}

class MeetingPointUpdate {
  final String pointId;
  final int sessionRevision;
  final MeetingPointAction action;
  final String creatorId;
  final String updatedBy;
  final int createdAt;
  final int updatedAt;
  final String? name;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final double? suggestedBoundaryRadiusMeters;

  const MeetingPointUpdate({
    required this.pointId,
    required this.sessionRevision,
    required this.action,
    required this.creatorId,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.suggestedBoundaryRadiusMeters = 100.0,
  });

  bool get isRemoval => action == MeetingPointAction.remove;

  Map<String, dynamic> toJson() => {
    'pointId': pointId,
    'sessionRevision': sessionRevision,
    'action': action.name,
    'creatorId': creatorId,
    'updatedBy': updatedBy,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    if (name != null) 'name': name,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
    if (suggestedBoundaryRadiusMeters != null)
      'suggestedBoundaryRadiusMeters': suggestedBoundaryRadiusMeters,
  };

  factory MeetingPointUpdate.fromJson(Map<String, dynamic> json) => MeetingPointUpdate(
    pointId: json['pointId'] as String,
    sessionRevision: json['sessionRevision'] as int,
    action: MeetingPointAction.values.firstWhere(
      (a) => a.name == json['action'],
      orElse: () => MeetingPointAction.upsert,
    ),
    creatorId: json['creatorId'] as String,
    updatedBy: json['updatedBy'] as String,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
    name: json['name'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
    suggestedBoundaryRadiusMeters:
        (json['suggestedBoundaryRadiusMeters'] as num?)?.toDouble() ?? 100.0,
  );
}
