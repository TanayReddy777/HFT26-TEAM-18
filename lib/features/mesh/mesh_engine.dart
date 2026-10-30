import 'dart:async';
import '../../core/models/envelope.dart';
import '../../core/contracts/mesh_transport.dart';
import '../../core/storage/local_database.dart';
import 'deduplication_cache.dart';
import 'store_and_forward_router.dart';

class MeshEngine {
  final String localNodeId;
  final String sessionId;
  final String sharedSecret;
  final MeshTransport transport;
  final LocalDatabase database;
  late final DeduplicationCache deduplicationCache;
  late final StoreAndForwardRouter router;

  final _receivedEnvelopesController = StreamController<Envelope>.broadcast();
  StreamSubscription<Envelope>? _transportSub;

  MeshEngine({
    required this.localNodeId,
    required this.sessionId,
    required this.sharedSecret,
    required this.transport,
    required this.database,
  }) {
    deduplicationCache = DeduplicationCache(capacity: 3000);
    router = StoreAndForwardRouter(
      localNodeId: localNodeId,
      sharedGroupSecret: sharedSecret,
      database: database,
      transport: transport,
      deduplicationCache: deduplicationCache,
    );
  }

  Stream<Envelope> get receivedEnvelopes => _receivedEnvelopesController.stream;
  List<String> get connectedPeers => transport.activeConnectedPeers;
  TransportType get transportType => transport.transportType;

  Future<void> initialize() async {
    await transport.initialize(localNodeId, sessionId);
    _transportSub = transport.incomingEnvelopes.listen((envelope) async {
      final processed = await router.handleIncomingEnvelope(envelope);
      if (processed != null) {
        _receivedEnvelopesController.add(processed);
      }
    });
  }

  /// Sends or broadcasts an envelope through the mesh
  Future<bool> sendEnvelope(Envelope envelope, {String? targetPeerId}) async {
    deduplicationCache.put(envelope.messageId);
    if (targetPeerId != null) {
      return await transport.send(envelope, targetPeerId);
    } else {
      final count = await transport.broadcast(envelope);
      return count > 0;
    }
  }

  Future<void> shutdown() async {
    await _transportSub?.cancel();
    await transport.shutdown();
  }
}
