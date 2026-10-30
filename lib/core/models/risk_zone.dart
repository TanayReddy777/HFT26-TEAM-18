enum RiskLevel {
  green,
  yellow,
  orange,
  red,
  unknown,
}

class RiskZone {
  final String id;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final RiskLevel riskLevel;
  final String description;
  final String sourceProvenance;
  final int? expiresAtEpochMs;
  final bool isDemoZone;

  const RiskZone({
    required this.id,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    required this.riskLevel,
    required this.description,
    required this.sourceProvenance,
    this.expiresAtEpochMs,
    this.isDemoZone = false,
  });

  bool isExpired(int nowMs) {
    if (expiresAtEpochMs == null) return false;
    return nowMs > expiresAtEpochMs!;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'centerLatitude': centerLatitude,
    'centerLongitude': centerLongitude,
    'radiusMeters': radiusMeters,
    'riskLevel': riskLevel.name,
    'description': description,
    'sourceProvenance': sourceProvenance,
    if (expiresAtEpochMs != null) 'expiresAtEpochMs': expiresAtEpochMs,
    'isDemoZone': isDemoZone,
  };

  factory RiskZone.fromJson(Map<String, dynamic> json) => RiskZone(
    id: json['id'] as String,
    name: json['name'] as String,
    centerLatitude: (json['centerLatitude'] as num).toDouble(),
    centerLongitude: (json['centerLongitude'] as num).toDouble(),
    radiusMeters: (json['radiusMeters'] as num).toDouble(),
    riskLevel: RiskLevel.values.firstWhere(
      (r) => r.name.toLowerCase() == json['riskLevel']?.toString().toLowerCase(),
      orElse: () => RiskLevel.unknown,
    ),
    description: json['description'] as String? ?? '',
    sourceProvenance: json['sourceProvenance'] as String? ?? 'Local DB',
    expiresAtEpochMs: json['expiresAtEpochMs'] as int?,
    isDemoZone: json['isDemoZone'] as bool? ?? false,
  );
}
