import 'dart:async';
import '../../core/contracts/mesh_transport.dart';
import '../../core/models/envelope.dart';
import 'multi_node_simulation_network.dart';

class FakeMeshTransport implements MeshTransport {
  final String nodeId;
  final MultiNodeSimulationNetwork network;
  final List<String> _connectedPeers = [];

  final _incomingController = StreamController<Envelope>.broadcast();
  final _connectionController = StreamController<PeerConnectionEvent>.broadcast();

  FakeMeshTransport({
    required this.nodeId,
    required this.network,
  });

  @override
  TransportType get transportType => TransportType.simulated;

  @override
  List<String> get activeConnectedPeers => List.unmodifiable(_connectedPeers);

  @override
  Stream<Envelope> get incomingEnvelopes => _incomingController.stream;

  @override
  Stream<PeerConnectionEvent> get peerConnectionEvents => _connectionController.stream;

  @override
  Future<void> initialize(String localNodeId, String sessionId) async {
    network.registerNode(this);
  }

  void setConnectedPeers(List<String> peerIds) {
    _connectedPeers.clear();
    _connectedPeers.addAll(peerIds);
    for (final peerId in peerIds) {
      _connectionController.add(PeerConnectionEvent(
        peerId: peerId,
        peerName: 'Simulated Peer $peerId',
        isConnected: true,
        transportType: TransportType.simulated,
      ));
    }
  }

  @override
  Future<bool> send(Envelope envelope, String targetPeerId) async {
    return network.routeDirect(nodeId, targetPeerId, envelope);
  }

  @override
  Future<int> broadcast(Envelope envelope) async {
    return network.routeBroadcast(nodeId, envelope);
  }

  void deliverIncoming(Envelope envelope) {
    _incomingController.add(envelope);
  }

  @override
  Future<void> shutdown() async {
    network.unregisterNode(nodeId);
    _connectedPeers.clear();
  }
}
