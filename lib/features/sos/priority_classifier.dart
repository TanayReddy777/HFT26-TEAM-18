import '../../core/constants/priorities.dart';

class PriorityClassificationResult {
  final Priority priority;
  final String ruleReason;
  final double confidence;

  const PriorityClassificationResult({
    required this.priority,
    required this.ruleReason,
    required this.confidence,
  });
}

class PriorityClassifier {
  static const List<String> _p0Keywords = [
    'trapped', 'unconscious', 'cannot breathe', 'severe bleeding',
    'heart attack', 'drowning', 'dying', 'building collapsed',
  ];

  static const List<String> _negationTokens = [
    'not', "don't", 'no', 'never', 'false alarm', 'cancelled', 'safe now',
  ];

  /// Classifies priority deterministically using offline rule engine
  static PriorityClassificationResult classify({
    required bool isExplicitSos,
    String? messageText,
    String? eventCode,
  }) {
    // 1. Explicit SOS is authoritative P0 and is NEVER downgraded
    if (isExplicitSos) {
      return const PriorityClassificationResult(
        priority: Priority.p0Critical,
        ruleReason: 'Explicit User SOS Trigger',
        confidence: 1.0,
      );
    }

    final text = messageText?.toLowerCase() ?? '';

    // Check for negation context
    bool hasNegation = false;
    for (final neg in _negationTokens) {
      if (text.contains(neg)) {
        hasNegation = true;
        break;
      }
    }

    // 2. Traumatic life-threat keywords without negation -> P0
    if (!hasNegation) {
      for (final kw in _p0Keywords) {
        if (text.contains(kw)) {
          return PriorityClassificationResult(
            priority: Priority.p0Critical,
            ruleReason: 'Detected critical life-threat keyword "$kw" without negation',
            confidence: 0.95,
          );
        }
      }
    }

    // 3. Event Code based classification
    if (eventCode != null) {
      switch (eventCode) {
        case 'CONFIRMED_SOS':
          return const PriorityClassificationResult(
            priority: Priority.p0Critical,
            ruleReason: 'Event code CONFIRMED_SOS',
            confidence: 1.0,
          );
        case 'POSSIBLE_FALL':
        case 'UNCONFIRMED_SOS':
        case 'USER_REQUESTED_HELP':
        case 'CONTACT_CHECK_UNANSWERED':
          return const PriorityClassificationResult(
            priority: Priority.p1Urgent,
            ruleReason: 'Urgent unconfirmed emergency safety check',
            confidence: 0.90,
          );
        case 'LOW_POWER_ALERT':
        case 'CRITICAL_LOW_POWER':
        case 'SEPARATION_WARNING':
        case 'SEPARATION_CRITICAL':
        case 'BOUNDARY_EXIT':
          return const PriorityClassificationResult(
            priority: Priority.p2Warning,
            ruleReason: 'Hazard / battery safety warning',
            confidence: 0.85,
          );
      }
    }

    // 4. Default normal chat / information -> P3
    return const PriorityClassificationResult(
      priority: Priority.p3Normal,
      ruleReason: 'Standard message / routine information',
      confidence: 1.0,
    );
  }
}
