import 'package:flutter_test/flutter_test.dart';
import 'package:resq/core/constants/priorities.dart';
import 'package:resq/features/sos/priority_classifier.dart';

void main() {
  group('Priority Classifier Tests', () {
    test('Explicit SOS is authoritative P0 Critical', () {
      final res = PriorityClassifier.classify(isExplicitSos: true);
      expect(res.priority, equals(Priority.p0Critical));
    });

    test('Life threatening keyword without negation classifies as P0 Critical', () {
      final res = PriorityClassifier.classify(
        isExplicitSos: false,
        messageText: 'Person trapped under debris and cannot breathe',
      );
      expect(res.priority, equals(Priority.p0Critical));
    });

    test('Life threatening keyword WITH negation is safely downgraded', () {
      final res = PriorityClassifier.classify(
        isExplicitSos: false,
        messageText: 'Not trapped, safe now, false alarm',
      );
      expect(res.priority, equals(Priority.p3Normal));
    });

    test('Urgent event code maps to P1 Urgent', () {
      final res = PriorityClassifier.classify(
        isExplicitSos: false,
        eventCode: 'POSSIBLE_FALL',
      );
      expect(res.priority, equals(Priority.p1Urgent));
    });

    test('Battery warning event maps to P2 Warning', () {
      final res = PriorityClassifier.classify(
        isExplicitSos: false,
        eventCode: 'LOW_POWER_ALERT',
      );
      expect(res.priority, equals(Priority.p2Warning));
    });
  });
}
