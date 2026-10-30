import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/intelligence/extractive_summarizer.dart';

void main() {
  group('Extractive Summarizer Tests', () {
    test('Short text is returned unchanged without loss', () {
      const short = 'We are walking towards camp.';
      final summary = ExtractiveSummarizer.extractSummary(short);
      expect(summary, equals(short));
    });

    test('Preserves negation and critical trauma keywords in order', () {
      const text =
          'We arrived at the eastern cliff. '
          'A rockfall occurred and 3 people are trapped with serious injury. '
          'We do not have enough water or medical kits. '
          'The team has portable radios.';

      final summary = ExtractiveSummarizer.extractSummary(text, maxSentences: 2);

      // Verify selected sentences contain critical details
      expect(summary.contains('trapped'), isTrue);
      expect(summary.contains('not'), isTrue);

      // Verify original narrative sentence order was strictly preserved
      final idxTrapped = summary.indexOf('trapped');
      final idxWater = summary.indexOf('water');
      expect(idxTrapped, lessThan(idxWater));
    });
  });
}
