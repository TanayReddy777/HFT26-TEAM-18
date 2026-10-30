class LocationUpdate {
  final String senderTrackingRunId;
  final int sequenceNumber;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final int recordedAt;
  final int fixAgeMillisAtSend;
  final double? speed;
  final double? bearing;

  const LocationUpdate({
    required this.senderTrackingRunId,
    required this.sequenceNumber,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.recordedAt,
    required this.fixAgeMillisAtSend,
    this.speed,
    this.bearing,
  });

  Map<String, dynamic> toJson() => {
    'senderTrackingRunId': senderTrackingRunId,
    'sequenceNumber': sequenceNumber,
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracyMeters,
    'recordedAt': recordedAt,
    'fixAgeMillisAtSend': fixAgeMillisAtSend,
    if (speed != null) 'speed': speed,
    if (bearing != null) 'bearing': bearing,
  };

  factory LocationUpdate.fromJson(Map<String, dynamic> json) => LocationUpdate(
    senderTrackingRunId: json['senderTrackingRunId'] as String,
    sequenceNumber: json['sequenceNumber'] as int,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
    recordedAt: json['recordedAt'] as int,
    fixAgeMillisAtSend: json['fixAgeMillisAtSend'] as int? ?? 0,
    speed: (json['speed'] as num?)?.toDouble(),
    bearing: (json['bearing'] as num?)?.toDouble(),
  );
}
