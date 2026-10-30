enum IntelligenceProcessingStatus {
  success,
  unsupportedLanguage,
  modelNotDownloaded,
  noTranslationNeeded,
  failed,
}

class ProcessedMessage {
  final String originalText;
  final String detectedLanguage;
  final String preferredLanguage;
  final String? translatedText;
  final String? summary;
  final bool wasTranslated;
  final bool wasSummarized;
  final IntelligenceProcessingStatus processingStatus;

  const ProcessedMessage({
    required this.originalText,
    required this.detectedLanguage,
    required this.preferredLanguage,
    this.translatedText,
    this.summary,
    required this.wasTranslated,
    required this.wasSummarized,
    required this.processingStatus,
  });
}

abstract class IntelligenceService {
  Future<ProcessedMessage> processMessage({
    required String originalText,
    required String preferredLanguage,
  });

  Future<bool> isModelDownloaded(String languageCode);
  Future<bool> downloadModel(String languageCode);
  Future<bool> deleteModel(String languageCode);
  List<String> getSupportedLanguages();
}
