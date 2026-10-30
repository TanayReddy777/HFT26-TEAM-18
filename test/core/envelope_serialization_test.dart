import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/core/models/envelope.dart';

void main() {
  group('Envelope Security & Routing Tests', () {
    const testSecret = 'resq_test_shared_secret';
    final now = DateTime.now().millisecondsSinceEpoch;

    test('Computes and verifies HMAC-SHA256 signature correctly', () {
      const payload = '{"incidentId":"123","type":"CONFIRMED_SOS"}';
      final sig = Envelope.computeSignature(payload, testSecret);

      final envelope = Envelope(
        messageId: 'MSG-001',
        sessionId: 'SESS-001',
        originId: 'NODE-A',
        messageKind: MessageKind.incident,
        originalOccurrenceTime: now,
        expiryPolicy: ExpiryPolicy(ttlMillis: 3600000, expiresAtMs: now + 3600000),
        signedPayload: payload,
        signature: sig,
      );

      expect(envelope.verifySignature(testSecret), isTrue);
      expect(envelope.verifySignature('wrong_secret'), isFalse);
    });

    test('Detects loops when node ID exists in relayPath or originId', () {
      final envelope = Envelope(
        messageId: 'MSG-002',
        sessionId: 'SESS-001',
        originId: 'NODE-A',
        messageKind: MessageKind.incident,
        originalOccurrenceTime: now,
        expiryPolicy: ExpiryPolicy(ttlMillis: 3600000, expiresAtMs: now + 3600000),
        signedPayload: '{}',
        signature: '',
        hopCount: 1,
        relayPath: ['NODE-B'],
      );

      expect(envelope.isLoopDetected('NODE-A'), isTrue);
      expect(envelope.isLoopDetected('NODE-B'), isTrue);
      expect(envelope.isLoopDetected('NODE-C'), isFalse);
    });

    test('Forwarded hop increments hopCount and preserves immutable signedPayload', () {
      const payload = '{"data":"immutable_content"}';
      final sig = Envelope.computeSignature(payload, testSecret);

      final initial = Envelope(
        messageId: 'MSG-003',
        sessionId: 'SESS-001',
        originId: 'NODE-A',
        messageKind: MessageKind.chat,
        originalOccurrenceTime: now,
        expiryPolicy: ExpiryPolicy(ttlMillis: 3600000, expiresAtMs: now + 3600000),
        signedPayload: payload,
        signature: sig,
        hopCount: 0,
        maxHops: 5,
      );

      final hopped = initial.createForwardedHop('NODE-B');

      expect(hopped.hopCount, equals(1));
      expect(hopped.relayPath, equals(['NODE-B']));
      expect(hopped.signedPayload, equals(initial.signedPayload));
      expect(hopped.signature, equals(initial.signature));
    });
  });
}
