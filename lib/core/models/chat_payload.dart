class ChatPayload {
  final String originalText;
  final String? sourceLanguageHint;
  final Map<String, dynamic>? attachmentMetadata;

  const ChatPayload({
    required this.originalText,
    this.sourceLanguageHint,
    this.attachmentMetadata,
  });

  Map<String, dynamic> toJson() => {
    'originalText': originalText,
    if (sourceLanguageHint != null) 'sourceLanguageHint': sourceLanguageHint,
    if (attachmentMetadata != null) 'attachmentMetadata': attachmentMetadata,
  };

  factory ChatPayload.fromJson(Map<String, dynamic> json) => ChatPayload(
    originalText: json['originalText'] as String,
    sourceLanguageHint: json['sourceLanguageHint'] as String?,
    attachmentMetadata: json['attachmentMetadata'] as Map<String, dynamic>?,
  );
}
