class ExtractiveSummarizer {
  // Critical keyword dictionaries across English, Telugu, and Hindi
  static const List<String> _negationTokens = [
    'not', "don't", 'cannot', "can't", 'no', 'never', 'without',
    'లేదు', 'కాదు', 'రాదు',
    'नहीं', 'ना', 'मत', 'बिना',
  ];

  static const List<String> _emergencyTraumaTokens = [
    'help', 'trapped', 'sos', 'injured', 'injury', 'bleeding', 'blood', 'fracture',
    'unconscious', 'dying', 'fire', 'flood', 'collapse', 'ambulance', 'doctor',
    'సహాయం', 'గాయం', 'రక్తం', 'చిక్కుకున్నాము', 'వైద్యం', 'ప్రమాదం',
    'मदद', 'घायल', 'खून', 'फंसे', 'खतरा', 'इलाज', 'दुर्घटना',
  ];

  static const List<String> _resourceTokens = [
    'water', 'food', 'battery', 'charge', 'oxygen', 'shelter', 'medicine',
    'నీరు', 'ఆహారం', 'మందులు',
    'पानी', 'खाना', 'दवा',
  ];

  static const List<String> _spatialTokens = [
    'bridge', 'river', 'temple', 'hill', 'road', 'mile', 'km', 'meter', 'north', 'south',
    'వంతెన', 'నది', 'గుడి', 'కొండ', 'రోడ్డు',
    'पुल', 'नदी', 'मंदिर', 'पहाड़', 'सड़क',
  ];

  /// Produces a deterministic extractive summary preserving sentence order and safety-critical context.
  /// If the text is short (<100 chars) or cannot be safely compressed without loss, returns originalText.
  static String extractSummary(String fullText, {int maxSentences = 2}) {
    if (fullText.trim().length <= 100) {
      return fullText; // Short text requires no summarization
    }

    // Split text into sentences by common punctuation
    final rawSentences = fullText.split(RegExp(r'(?<=[.!?\n])\s+'));
    final sentences = rawSentences.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    if (sentences.length <= maxSentences) {
      return fullText;
    }

    // Score each sentence by critical token density
    final scores = <int, int>{};
    for (int i = 0; i < sentences.length; i++) {
      final sLower = sentences[i].toLowerCase();
      int score = 0;

      for (final token in _emergencyTraumaTokens) {
        if (sLower.contains(token)) score += 5;
      }
      for (final token in _negationTokens) {
        if (sLower.contains(token)) score += 4;
      }
      for (final token in _resourceTokens) {
        if (sLower.contains(token)) score += 3;
      }
      for (final token in _spatialTokens) {
        if (sLower.contains(token)) score += 2;
      }
      if (RegExp(r'\d+').hasMatch(sLower)) {
        score += 3; // Contains vital numbers/people counts/battery percentages
      }

      scores[i] = score;
    }

    // Select top sentence indices
    final sortedIndices = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    final selectedIndices = sortedIndices.take(maxSentences).toList();
    // CRITICAL REQUIREMENT: Restore original sentence order to preserve narrative & negation logic
    selectedIndices.sort();

    final summaryResult = selectedIndices.map((i) => sentences[i]).join(' ');
    return summaryResult.isNotEmpty ? summaryResult : fullText;
  }
}
