import '../models/envelope.dart';

enum TransportType {
  bluetoothOnly,
  nearbyHybrid,
  simulated,
}

class PeerConnectionEvent {
  final String peerId;
  final String peerName;
  final bool isConnected;
  final TransportType transportType;

  const PeerConnectionEvent({
    required this.peerId,
    required this.peerName,
    required this.isConnected,
    required this.transportType,
  });
}

abstract class MeshTransport {
  TransportType get transportType;
  List<String> get activeConnectedPeers;

  Stream<Envelope> get incomingEnvelopes;
  Stream<PeerConnectionEvent> get peerConnectionEvents;

  Future<void> initialize(String localNodeId, String sessionId);
  Future<bool> send(Envelope envelope, String targetPeerId);
  Future<int> broadcast(Envelope envelope);
  Future<void> shutdown();
}
