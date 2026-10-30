class LocationSnapshot {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final int recordedAt;
  final bool isHistorical;

  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.recordedAt,
    this.isHistorical = false,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracyMeters,
    'recordedAt': recordedAt,
    'isHistorical': isHistorical,
  };

  factory LocationSnapshot.fromJson(Map<String, dynamic> json) => LocationSnapshot(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
    recordedAt: json['recordedAt'] as int,
    isHistorical: json['isHistorical'] as bool? ?? false,
  );
}
