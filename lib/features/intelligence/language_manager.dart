import 'dart:async';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class LanguagePackInfo {
  final String code;
  final String name;
  final bool isDownloaded;
  final bool isDownloading;

  const LanguagePackInfo({
    required this.code,
    required this.name,
    required this.isDownloaded,
    this.isDownloading = false,
  });

  LanguagePackInfo copyWith({
    bool? isDownloaded,
    bool? isDownloading,
  }) {
    return LanguagePackInfo(
      code: code,
      name: name,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }
}

class LanguageManager {
  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();

  static const Map<String, String> supportedLanguageMap = {
    'en': 'English',
    'te': 'Telugu (తెలుగు)',
    'hi': 'Hindi (हिन्दी)',
    'ta': 'Tamil (தமிழ்)',
    'kn': 'Kannada (ಕನ್ನಡ)',
  };

  final Map<String, LanguagePackInfo> _packStates = {};
  final _packStatusController = StreamController<List<LanguagePackInfo>>.broadcast();

  Stream<List<LanguagePackInfo>> get packStatusStream => _packStatusController.stream;

  LanguageManager() {
    for (final entry in supportedLanguageMap.entries) {
      _packStates[entry.key] = LanguagePackInfo(
        code: entry.key,
        name: entry.value,
        isDownloaded: entry.key == 'en', // English base is built-in
      );
    }
  }

  List<LanguagePackInfo> getAllPacks() => _packStates.values.toList();

  Future<void> refreshPackStatuses() async {
    for (final code in supportedLanguageMap.keys) {
      try {
        final bcpCode = _mapToTranslateLanguage(code);
        final isDownloaded = await _modelManager.isModelDownloaded(bcpCode.bcpCode);
        _packStates[code] = _packStates[code]!.copyWith(
          isDownloaded: isDownloaded,
          isDownloading: false,
        );
      } catch (_) {
        // Fallback for non-Android platforms / headless test
      }
    }
    _packStatusController.add(getAllPacks());
  }

  Future<bool> downloadPack(String code) async {
    if (!_packStates.containsKey(code)) return false;

    _packStates[code] = _packStates[code]!.copyWith(isDownloading: true);
    _packStatusController.add(getAllPacks());

    try {
      final bcpCode = _mapToTranslateLanguage(code);
      final success = await _modelManager.downloadModel(bcpCode.bcpCode);
      _packStates[code] = _packStates[code]!.copyWith(
        isDownloaded: success,
        isDownloading: false,
      );
      _packStatusController.add(getAllPacks());
      return success;
    } catch (_) {
      _packStates[code] = _packStates[code]!.copyWith(isDownloading: false);
      _packStatusController.add(getAllPacks());
      return false;
    }
  }

  Future<bool> deletePack(String code) async {
    if (!_packStates.containsKey(code)) return false;

    try {
      final bcpCode = _mapToTranslateLanguage(code);
      final success = await _modelManager.deleteModel(bcpCode.bcpCode);
      _packStates[code] = _packStates[code]!.copyWith(isDownloaded: !success);
      _packStatusController.add(getAllPacks());
      return success;
    } catch (_) {
      return false;
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
}
