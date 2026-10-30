import 'dart:convert';
import '../../core/models/envelope.dart';
import '../../core/models/receipt.dart';
import '../../core/contracts/mesh_transport.dart';
import '../../core/storage/local_database.dart';
import 'deduplication_cache.dart';

class StoreAndForwardRouter {
  final String localNodeId;
  final String sharedGroupSecret;
  final LocalDatabase database;
  final MeshTransport transport;
  final DeduplicationCache deduplicationCache;

  // Track which peers have acknowledged which message IDs to avoid rebroadcasting
  final Map<String, Set<String>> _peerAcks = {};

  StoreAndForwardRouter({
    required this.localNodeId,
    required this.sharedGroupSecret,
    required this.database,
    required this.transport,
    required this.deduplicationCache,
  });

  /// Processes an incoming envelope from transport
  Future<Envelope?> handleIncomingEnvelope(Envelope envelope) async {
    // 1. Deduplication check
    if (deduplicationCache.contains(envelope.messageId)) {
      return null;
    }
    deduplicationCache.put(envelope.messageId);

    // 2. Validate cryptographic signature
    if (!envelope.verifySignature(sharedGroupSecret)) {
      return null;
    }

    // 3. Expiry validation
    final now = DateTime.now().millisecondsSinceEpoch;
    if (envelope.expiryPolicy.isExpired(now)) {
      return null;
    }

    // 4. Loop prevention
    if (envelope.isLoopDetected(localNodeId)) {
      return null;
    }

    // 5. Check if local node should forward along the mesh
    if (envelope.canForward()) {
      await _forwardEnvelopeToEligiblePeers(envelope);
    }

    return envelope;
  }

  /// Automatically relays envelope to adjacent peers that haven't seen it yet
  Future<void> _forwardEnvelopeToEligiblePeers(Envelope envelope) async {
    final forwardedEnvelope = envelope.createForwardedHop(localNodeId);
    final connectedPeers = transport.activeConnectedPeers;

    for (final peerId in connectedPeers) {
      // Don't bounce back to origin or nodes already in the relay chain
      if (peerId == envelope.originId || envelope.relayPath.contains(peerId)) {
        continue;
      }

      // Don't send if peer already acknowledged this message
      if (_peerAcks[envelope.messageId]?.contains(peerId) ?? false) {
        continue;
      }

      await transport.send(forwardedEnvelope, peerId);
    }
  }

  void recordPeerAcknowledgement(String messageId, String peerId) {
    _peerAcks.putIfAbsent(messageId, () => {}).add(peerId);
  }
}
