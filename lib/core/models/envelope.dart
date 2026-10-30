import 'dart:convert';
import 'package:crypto/crypto.dart';

enum MessageKind {
  chat,
  location,
  meetingPoint,
  incident,
  receipt,
}

class ExpiryPolicy {
  final int ttlMillis;
  final int expiresAtMs;

  const ExpiryPolicy({
    required this.ttlMillis,
    required this.expiresAtMs,
  });

  bool isExpired(int currentMonotonicOrEpochMs) => currentMonotonicOrEpochMs > expiresAtMs;

  Map<String, dynamic> toJson() => {
    'ttlMillis': ttlMillis,
    'expiresAtMs': expiresAtMs,
  };

  factory ExpiryPolicy.fromJson(Map<String, dynamic> json) => ExpiryPolicy(
    ttlMillis: json['ttlMillis'] as int? ?? 3600000,
    expiresAtMs: json['expiresAtMs'] as int? ?? (DateTime.now().millisecondsSinceEpoch + 3600000),
  );
}

/// Canonical Envelope carrying immutable signed payload across multi-hop mesh relays.
class Envelope {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String messageId;
  final String sessionId;
  final String originId;
  final List<String> intendedRecipients; // Empty list implies broadcast to session
  final MessageKind messageKind;
  final int originalOccurrenceTime; // Epoch ms of initial creation
  final ExpiryPolicy expiryPolicy;
  final String signedPayload; // Immutable serialized payload
  final String signature; // Integrity authentication tag

  // Forwarding metadata (mutable per hop, validated against loop & hop limits)
  final int hopCount;
  final int maxHops;
  final List<String> relayPath; // List of node IDs that relayed this envelope

  const Envelope({
    this.schemaVersion = currentSchemaVersion,
    required this.messageId,
    required this.sessionId,
    required this.originId,
    this.intendedRecipients = const [],
    required this.messageKind,
    required this.originalOccurrenceTime,
    required this.expiryPolicy,
    required this.signedPayload,
    required this.signature,
    this.hopCount = 0,
    this.maxHops = 5,
    this.relayPath = const [],
  });

  /// Creates a forwarded envelope copy incrementing hopCount and recording the relayer
  Envelope createForwardedHop(String relayerNodeId) {
    return Envelope(
      schemaVersion: schemaVersion,
      messageId: messageId,
      sessionId: sessionId,
      originId: originId,
      intendedRecipients: List.unmodifiable(intendedRecipients),
      messageKind: messageKind,
      originalOccurrenceTime: originalOccurrenceTime,
      expiryPolicy: expiryPolicy,
      signedPayload: signedPayload, // Never altered across relays
      signature: signature,
      hopCount: hopCount + 1,
      maxHops: maxHops,
      relayPath: [...relayPath, relayerNodeId],
    );
  }

  bool isLoopDetected(String candidateNodeId) => relayPath.contains(candidateNodeId) || originId == candidateNodeId;

  bool canForward() => hopCount < maxHops;

  static String computeSignature(String payload, String sharedSecret) {
    final key = utf8.encode(sharedSecret);
    final bytes = utf8.encode(payload);
    final hmacSha256 = Hmac(sha256, key);
    return hmacSha256.convert(bytes).toString();
  }

  bool verifySignature(String sharedSecret) {
    final expected = computeSignature(signedPayload, sharedSecret);
    return expected == signature;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'messageId': messageId,
    'sessionId': sessionId,
    'originId': originId,
    'intendedRecipients': intendedRecipients,
    'messageKind': messageKind.name,
    'originalOccurrenceTime': originalOccurrenceTime,
    'expiryPolicy': expiryPolicy.toJson(),
    'signedPayload': signedPayload,
    'signature': signature,
    'hopCount': hopCount,
    'maxHops': maxHops,
    'relayPath': relayPath,
  };

  factory Envelope.fromJson(Map<String, dynamic> json) => Envelope(
    schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
    messageId: json['messageId'] as String,
    sessionId: json['sessionId'] as String,
    originId: json['originId'] as String,
    intendedRecipients: (json['intendedRecipients'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    messageKind: MessageKind.values.firstWhere(
      (k) => k.name == json['messageKind'],
      orElse: () => MessageKind.chat,
    ),
    originalOccurrenceTime: json['originalOccurrenceTime'] as int,
    expiryPolicy: ExpiryPolicy.fromJson(json['expiryPolicy'] as Map<String, dynamic>),
    signedPayload: json['signedPayload'] as String,
    signature: json['signature'] as String? ?? '',
    hopCount: json['hopCount'] as int? ?? 0,
    maxHops: json['maxHops'] as int? ?? 5,
    relayPath: (json['relayPath'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
  );
}
