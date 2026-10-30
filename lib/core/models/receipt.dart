enum ReceiptType {
  stored,
  delivered,
  removed,
  ackUser,
  volunteerHelp,
}

class Receipt {
  final int schemaVersion;
  final String messageId;
  final String sessionId;
  final String referencedId;
  final int exactRevision;
  final String memberId;
  final ReceiptType receiptType;
  final int receiptTime;

  const Receipt({
    this.schemaVersion = 1,
    required this.messageId,
    required this.sessionId,
    required this.referencedId,
    required this.exactRevision,
    required this.memberId,
    required this.receiptType,
    required this.receiptTime,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'messageId': messageId,
    'sessionId': sessionId,
    'referencedId': referencedId,
    'exactRevision': exactRevision,
    'memberId': memberId,
    'receiptType': receiptType.name,
    'receiptTime': receiptTime,
  };

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
    schemaVersion: json['schemaVersion'] as int? ?? 1,
    messageId: json['messageId'] as String,
    sessionId: json['sessionId'] as String,
    referencedId: json['referencedId'] as String,
    exactRevision: json['exactRevision'] as int,
    memberId: json['memberId'] as String,
    receiptType: ReceiptType.values.firstWhere(
      (r) => r.name == json['receiptType'],
      orElse: () => ReceiptType.stored,
    ),
    receiptTime: json['receiptTime'] as int,
  );
}
