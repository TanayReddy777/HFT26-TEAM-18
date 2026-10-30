import '../../core/models/envelope.dart';
import 'fake_mesh_transport.dart';

class MultiNodeSimulationNetwork {
  final Map<String, FakeMeshTransport> _nodes = {};
  final Map<String, Set<String>> _links = {};

  void registerNode(FakeMeshTransport transport) {
    _nodes[transport.nodeId] = transport;
    _links.putIfAbsent(transport.nodeId, () => {});
  }

  void unregisterNode(String nodeId) {
    _nodes.remove(nodeId);
    _links.remove(nodeId);
    for (final neighbors in _links.values) {
      neighbors.remove(nodeId);
    }
  }

  /// Adds a bidirectional radio link between two nodes
  void establishLink(String nodeA, String nodeB) {
    _links.putIfAbsent(nodeA, () => {}).add(nodeB);
    _links.putIfAbsent(nodeB, () => {}).add(nodeA);

    _nodes[nodeA]?.setConnectedPeers(_links[nodeA]!.toList());
    _nodes[nodeB]?.setConnectedPeers(_links[nodeB]!.toList());
  }

  /// Removes radio connectivity between two nodes
  void breakLink(String nodeA, String nodeB) {
    _links[nodeA]?.remove(nodeB);
    _links[nodeB]?.remove(nodeA);

    _nodes[nodeA]?.setConnectedPeers(_links[nodeA]?.toList() ?? []);
    _nodes[nodeB]?.setConnectedPeers(_links[nodeB]?.toList() ?? []);
  }

  bool routeDirect(String senderId, String recipientId, Envelope envelope) {
    if (!(_links[senderId]?.contains(recipientId) ?? false)) {
      return false; // No direct RF link between nodes
    }
    final target = _nodes[recipientId];
    if (target != null) {
      target.deliverIncoming(envelope);
      return true;
    }
    return false;
  }

  int routeBroadcast(String senderId, Envelope envelope) {
    final neighbors = _links[senderId] ?? {};
    int deliveredCount = 0;
    for (final neighborId in neighbors) {
      final target = _nodes[neighborId];
      if (target != null) {
        target.deliverIncoming(envelope);
        deliveredCount++;
      }
    }
    return deliveredCount;
  }

  void clear() {
    _nodes.clear();
    _links.clear();
  }
}
