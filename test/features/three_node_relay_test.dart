import 'package:flutter_test/flutter_test.dart';
import 'package:resq/core/constants/priorities.dart';
import 'package:resq/core/models/envelope.dart';
import 'package:resq/core/models/incident_snapshot.dart';
import 'package:resq/core/storage/local_database.dart';
import 'package:resq/features/mesh/mesh_engine.dart';
import 'package:resq/testing/fakes/fake_mesh_transport.dart';
import 'package:resq/testing/fakes/multi_node_simulation_network.dart';

void main() {
  group('3-Node Store-and-Forward Mesh Relay Tests (A -> B -> C)', () {
    late MultiNodeSimulationNetwork network;
    late LocalDatabase dbA;
    late LocalDatabase dbB;
    late LocalDatabase dbC;
    late MeshEngine engineA;
    late MeshEngine engineB;
    late MeshEngine engineC;

    const sharedSecret = 'test_mesh_key_123';

    setUp(() async {
      network = MultiNodeSimulationNetwork();

      dbA = LocalDatabase();
      dbB = LocalDatabase();
      dbC = LocalDatabase();

      final transportA = FakeMeshTransport(nodeId: 'NODE_A', network: network);
      final transportB = FakeMeshTransport(nodeId: 'NODE_B', network: network);
      final transportC = FakeMeshTransport(nodeId: 'NODE_C', network: network);

      engineA = MeshEngine(
        localNodeId: 'NODE_A',
        sessionId: 'SESS_1',
        sharedSecret: sharedSecret,
        transport: transportA,
        database: dbA,
      );

      engineB = MeshEngine(
        localNodeId: 'NODE_B',
        sessionId: 'SESS_1',
        sharedSecret: sharedSecret,
        transport: transportB,
        database: dbB,
      );

      engineC = MeshEngine(
        localNodeId: 'NODE_C',
        sessionId: 'SESS_1',
        sharedSecret: sharedSecret,
        transport: transportC,
        database: dbC,
      );

      await engineA.initialize();
      await engineB.initialize();
      await engineC.initialize();

      // Configure linear topology: A <-> B <-> C (NO direct link between A and C)
      network.establishLink('NODE_A', 'NODE_B');
      network.establishLink('NODE_B', 'NODE_C');
    });

    test('Node A transmits SOS, Node B automatically forwards to Node C', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final payload = '{"incidentId":"INC-777","type":"CONFIRMED_SOS","severity":0}';
      final sig = Envelope.computeSignature(payload, sharedSecret);

      final sosEnvelope = Envelope(
        messageId: 'MSG-SOS-777',
        sessionId: 'SESS_1',
        originId: 'NODE_A',
        intendedRecipients: ['NODE_C'],
        messageKind: MessageKind.incident,
        originalOccurrenceTime: now,
        expiryPolicy: ExpiryPolicy(ttlMillis: 3600000, expiresAtMs: now + 3600000),
        signedPayload: payload,
        signature: sig,
        hopCount: 0,
        maxHops: 5,
        relayPath: ['NODE_A'],
      );

      Envelope? receivedAtC;
      engineC.receivedEnvelopes.listen((env) {
        receivedAtC = env;
      });

      // A sends to adjacent peer B
      await engineA.sendEnvelope(sosEnvelope, targetPeerId: 'NODE_B');

      // Wait brief tick for relay traversal
      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedAtC, isNotNull);
      expect(receivedAtC!.messageId, equals('MSG-SOS-777'));
      expect(receivedAtC!.hopCount, equals(1));
      expect(receivedAtC!.relayPath, contains('NODE_B'));
    });
  });
}
