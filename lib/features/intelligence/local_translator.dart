import 'dart:async';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../../core/contracts/intelligence_service.dart';
import 'extractive_summarizer.dart';
import 'language_manager.dart';

class LocalTranslator implements IntelligenceService {
  final LanguageManager languageManager;
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);

  final Map<String, OnDeviceTranslator> _activeTranslators = {};

  LocalTranslator({required this.languageManager});

  @override
  List<String> getSupportedLanguages() => LanguageManager.supportedLanguageMap.keys.toList();

  @override
  Future<bool> isModelDownloaded(String languageCode) async {
    final pack = languageManager.getAllPacks().firstWhere(
      (p) => p.code == languageCode,
      orElse: () => const LanguagePackInfo(code: '', name: '', isDownloaded: false),
    );
    return pack.isDownloaded;
  }

  @override
  Future<bool> downloadModel(String languageCode) => languageManager.downloadPack(languageCode);

  @override
  Future<bool> deleteModel(String languageCode) => languageManager.deletePack(languageCode);

  @override
  Future<ProcessedMessage> processMessage({
    required String originalText,
    required String preferredLanguage,
  }) async {
    // 1. Language Identification
    String detectedLang = 'en';
    try {
      final identified = await _languageIdentifier.identifyLanguage(originalText);
      if (identified != 'und') {
        detectedLang = identified;
      }
    } catch (_) {
      // Heuristic fallback
      if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(originalText)) {
        detectedLang = 'te'; // Telugu unicode block
      } else if (RegExp(r'[\u0900-\u097F]').hasMatch(originalText)) {
        detectedLang = 'hi'; // Devanagari unicode block
      } else if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(originalText)) {
        detectedLang = 'ta'; // Tamil unicode block
      } else if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(originalText)) {
        detectedLang = 'kn'; // Kannada unicode block
      }
    }

    // 2. Extractive Summary
    final summary = ExtractiveSummarizer.extractSummary(originalText);
    final wasSummarized = summary != originalText;

    // 3. Translation Check
    if (detectedLang == preferredLanguage) {
      return ProcessedMessage(
        originalText: originalText,
        detectedLanguage: detectedLang,
        preferredLanguage: preferredLanguage,
        translatedText: null,
        summary: summary,
        wasTranslated: false,
        wasSummarized: wasSummarized,
        processingStatus: IntelligenceProcessingStatus.noTranslationNeeded,
      );
    }

    // Check if target model pack is installed
    final isPackDownloaded = await isModelDownloaded(preferredLanguage);
    if (!isPackDownloaded) {
      return ProcessedMessage(
        originalText: originalText,
        detectedLanguage: detectedLang,
        preferredLanguage: preferredLanguage,
        translatedText: null,
        summary: summary,
        wasTranslated: false,
        wasSummarized: wasSummarized,
        processingStatus: IntelligenceProcessingStatus.modelNotDownloaded,
      );
    }

    try {
      final source = _mapToTranslateLanguage(detectedLang);
      final target = _mapToTranslateLanguage(preferredLanguage);
      final translatorKey = '${source.bcpCode}_${target.bcpCode}';

      final translator = _activeTranslators.putIfAbsent(
        translatorKey,
        () => OnDeviceTranslator(sourceLanguage: source, targetLanguage: target),
      );

      final translated = await translator.translateText(originalText);
      return ProcessedMessage(
        originalText: originalText,
        detectedLanguage: detectedLang,
        preferredLanguage: preferredLanguage,
        translatedText: translated,
        summary: summary,
        wasTranslated: true,
        wasSummarized: wasSummarized,
        processingStatus: IntelligenceProcessingStatus.success,
      );
    } catch (e) {
      return ProcessedMessage(
        originalText: originalText,
        detectedLanguage: detectedLang,
        preferredLanguage: preferredLanguage,
        translatedText: null,
        summary: summary,
        wasTranslated: false,
        wasSummarized: wasSummarized,
        processingStatus: IntelligenceProcessingStatus.failed,
      );
    }
  }

  TranslateLanguage _mapToTranslateLanguage(String code) {
    switch (code) {
      case 'te':
        return TranslateLanguage.telugu;
      case 'hi':
        return TranslateLanguage.hindi;
      case 'ta':
        return TranslateLanguage.tamil;
      case 'kn':
        return TranslateLanguage.kannada;
      case 'en':
      default:
        return TranslateLanguage.english;
    }
  }

  void dispose() {
    _languageIdentifier.close();
    for (final translator in _activeTranslators.values) {
      translator.close();
    }
    _activeTranslators.clear();
  }
}
