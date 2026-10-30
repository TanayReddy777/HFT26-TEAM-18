class Member {
  final String id;
  final String displayName;
  final String publicKey;
  final bool isLeader;
  final bool isPrimaryBuddy;
  final int lastSeenEpochMs;
  final double? lastLatitude;
  final double? lastLongitude;
  final double? lastAccuracyMeters;
  final int? lastFixEpochMs;
  final double? batteryPercentage;

  const Member({
    required this.id,
    required this.displayName,
    required this.publicKey,
    this.isLeader = false,
    this.isPrimaryBuddy = false,
    required this.lastSeenEpochMs,
    this.lastLatitude,
    this.lastLongitude,
    this.lastAccuracyMeters,
    this.lastFixEpochMs,
    this.batteryPercentage,
  });

  Member copyWith({
    String? displayName,
    String? publicKey,
    bool? isLeader,
    bool? isPrimaryBuddy,
    int? lastSeenEpochMs,
    double? lastLatitude,
    double? lastLongitude,
    double? lastAccuracyMeters,
    int? lastFixEpochMs,
    double? batteryPercentage,
  }) {
    return Member(
      id: id,
      displayName: displayName ?? this.displayName,
      publicKey: publicKey ?? this.publicKey,
      isLeader: isLeader ?? this.isLeader,
      isPrimaryBuddy: isPrimaryBuddy ?? this.isPrimaryBuddy,
      lastSeenEpochMs: lastSeenEpochMs ?? this.lastSeenEpochMs,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastAccuracyMeters: lastAccuracyMeters ?? this.lastAccuracyMeters,
      lastFixEpochMs: lastFixEpochMs ?? this.lastFixEpochMs,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'publicKey': publicKey,
    'isLeader': isLeader,
    'isPrimaryBuddy': isPrimaryBuddy,
    'lastSeenEpochMs': lastSeenEpochMs,
    if (lastLatitude != null) 'lastLatitude': lastLatitude,
    if (lastLongitude != null) 'lastLongitude': lastLongitude,
    if (lastAccuracyMeters != null) 'lastAccuracyMeters': lastAccuracyMeters,
    if (lastFixEpochMs != null) 'lastFixEpochMs': lastFixEpochMs,
    if (batteryPercentage != null) 'batteryPercentage': batteryPercentage,
  };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    publicKey: json['publicKey'] as String,
    isLeader: json['isLeader'] as bool? ?? false,
    isPrimaryBuddy: json['isPrimaryBuddy'] as bool? ?? false,
    lastSeenEpochMs: json['lastSeenEpochMs'] as int? ?? 0,
    lastLatitude: (json['lastLatitude'] as num?)?.toDouble(),
    lastLongitude: (json['lastLongitude'] as num?)?.toDouble(),
    lastAccuracyMeters: (json['lastAccuracyMeters'] as num?)?.toDouble(),
    lastFixEpochMs: json['lastFixEpochMs'] as int?,
    batteryPercentage: (json['batteryPercentage'] as num?)?.toDouble(),
  );
}
