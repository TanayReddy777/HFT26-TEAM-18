import '../constants/priorities.dart';
import 'location_snapshot.dart';

enum IncidentStatus {
  active,
  acknowledged,
  safe,
  resolved,
  timeout,
}

enum ConfirmationStatus {
  unconfirmed,
  confirmedSafe,
  confirmedHelp,
  noResponse,
}

class IncidentSnapshot {
  final String incidentId;
  final int incidentRevision;
  final String sourceModule;
  final String sourceUserId;
  final String? relatedUserId;
  final String type; // EventCode constant
  final IncidentStatus status;
  final Priority severity;
  final ConfirmationStatus confirmationStatus;
  final int occurredAt;
  final int updatedAt;
  final bool explicitSos;
  final LocationSnapshot? locationContext;
  final double? batteryContext;
  final String? zoneContext;
  final String? meetingPointContext;

  const IncidentSnapshot({
    required this.incidentId,
    required this.incidentRevision,
    required this.sourceModule,
    required this.sourceUserId,
    this.relatedUserId,
    required this.type,
    required this.status,
    required this.severity,
    required this.confirmationStatus,
    required this.occurredAt,
    required this.updatedAt,
    required this.explicitSos,
    this.locationContext,
    this.batteryContext,
    this.zoneContext,
    this.meetingPointContext,
  });

  /// Creates a revised snapshot with incremented revision number and updated timestamp
  IncidentSnapshot createRevision({
    required int newRevision,
    String? newType,
    IncidentStatus? newStatus,
    Priority? newSeverity,
    ConfirmationStatus? newConfirmationStatus,
    LocationSnapshot? newLocationContext,
    double? newBatteryContext,
    String? newZoneContext,
    String? newMeetingPointContext,
  }) {
    return IncidentSnapshot(
      incidentId: incidentId,
      incidentRevision: newRevision,
      sourceModule: sourceModule,
      sourceUserId: sourceUserId,
      relatedUserId: relatedUserId,
      type: newType ?? type,
      status: newStatus ?? status,
      severity: newSeverity ?? severity,
      confirmationStatus: newConfirmationStatus ?? confirmationStatus,
      occurredAt: occurredAt, // Preserved immutable original time
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      explicitSos: explicitSos,
      locationContext: newLocationContext ?? locationContext,
      batteryContext: newBatteryContext ?? batteryContext,
      zoneContext: newZoneContext ?? zoneContext,
      meetingPointContext: newMeetingPointContext ?? meetingPointContext,
    );
  }

  Map<String, dynamic> toJson() => {
    'incidentId': incidentId,
    'incidentRevision': incidentRevision,
    'sourceModule': sourceModule,
    'sourceUserId': sourceUserId,
    if (relatedUserId != null) 'relatedUserId': relatedUserId,
    'type': type,
    'status': status.name,
    'severity': severity.level,
    'confirmationStatus': confirmationStatus.name,
    'occurredAt': occurredAt,
    'updatedAt': updatedAt,
    'explicitSos': explicitSos,
    if (locationContext != null) 'locationContext': locationContext!.toJson(),
    if (batteryContext != null) 'batteryContext': batteryContext,
    if (zoneContext != null) 'zoneContext': zoneContext,
    if (meetingPointContext != null)
      'meetingPointContext': meetingPointContext,
  };

  factory IncidentSnapshot.fromJson(Map<String, dynamic> json) => IncidentSnapshot(
    incidentId: json['incidentId'] as String,
    incidentRevision: json['incidentRevision'] as int,
    sourceModule: json['sourceModule'] as String,
    sourceUserId: json['sourceUserId'] as String,
    relatedUserId: json['relatedUserId'] as String?,
    type: json['type'] as String,
    status: IncidentStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => IncidentStatus.active,
    ),
    severity: Priority.fromLevel(json['severity'] as int? ?? 1),
    confirmationStatus: ConfirmationStatus.values.firstWhere(
      (c) => c.name == json['confirmationStatus'],
      orElse: () => ConfirmationStatus.unconfirmed,
    ),
    occurredAt: json['occurredAt'] as int,
    updatedAt: json['updatedAt'] as int,
    explicitSos: json['explicitSos'] as bool? ?? false,
    locationContext: json['locationContext'] != null
        ? LocationSnapshot.fromJson(
            json['locationContext'] as Map<String, dynamic>)
        : null,
    batteryContext: (json['batteryContext'] as num?)?.toDouble(),
    zoneContext: json['zoneContext'] as String?,
    meetingPointContext: json['meetingPointContext'] as String?,
  );
}
