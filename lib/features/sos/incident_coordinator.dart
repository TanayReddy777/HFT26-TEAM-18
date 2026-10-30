import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../core/constants/priorities.dart';
import '../../core/contracts/incident_service.dart';
import '../../core/contracts/session_provider.dart';
import '../../core/contracts/location_provider.dart';
import '../../core/models/envelope.dart';
import '../../core/models/incident_snapshot.dart';
import '../../core/models/receipt.dart';
import '../../core/storage/local_database.dart';
import '../mesh/mesh_engine.dart';
import 'delivery_tracker.dart';
import 'priority_classifier.dart';

class IncidentCoordinator implements IncidentService {
  final LocalDatabase database;
  final SessionProvider sessionProvider;
  final LocationProvider locationProvider;
  final MeshEngine meshEngine;
  final DeliveryTracker deliveryTracker = DeliveryTracker();

  final _incidentsStreamController = StreamController<List<IncidentSnapshot>>.broadcast();
  Timer? _outboxSchedulerTimer;

  IncidentCoordinator({
    required this.database,
    required this.sessionProvider,
    required this.locationProvider,
    required this.meshEngine,
  }) {
    // Listen to database changes and forward to public stream
    database.incidentsStream.listen((list) {
      _incidentsStreamController.add(list);
    });

    // Start outbox processing loop (checks every 2 seconds for pending queued messages)
    _startOutboxScheduler();

    // Listen to incoming envelopes from mesh engine
    meshEngine.receivedEnvelopes.listen(_handleIncomingMeshEnvelope);
  }

  @override
  List<IncidentSnapshot> get activeIncidents => database.getAllIncidents();

  @override
  Stream<List<IncidentSnapshot>> get incidentsStream => _incidentsStreamController.stream;

  @override
  Future<IncidentSnapshot> submitIncident({
    required String sourceModule,
    required String eventCode,
    required Priority severity,
    required bool explicitSos,
    String? relatedUserId,
    String? reason,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final incidentId = const Uuid().v4();
    final messageId = const Uuid().v4();

    final fix = locationProvider.latestFix;

    final incident = IncidentSnapshot(
      incidentId: incidentId,
      incidentRevision: 1,
      sourceModule: sourceModule,
      sourceUserId: sessionProvider.localNodeId,
      relatedUserId: relatedUserId,
      type: eventCode,
      status: IncidentStatus.active,
      severity: severity,
      confirmationStatus: explicitSos ? ConfirmationStatus.confirmedHelp : ConfirmationStatus.unconfirmed,
      occurredAt: now,
      updatedAt: now,
      explicitSos: explicitSos,
      locationContext: fix,
    );

    // 1. Durable atomic persistence locally before transmission
    await database.saveIncident(incident);

    // 2. Package into canonical Envelope
    final payloadJson = jsonEncode(incident.toJson());
    final signature = Envelope.computeSignature(payloadJson, sessionProvider.sharedGroupSecret);

    final envelope = Envelope(
      messageId: messageId,
      sessionId: sessionProvider.currentSessionId,
      originId: sessionProvider.localNodeId,
      intendedRecipients: sessionProvider.authorizedMembers.map((m) => m.id).toList(),
      messageKind: MessageKind.incident,
      originalOccurrenceTime: now,
      expiryPolicy: ExpiryPolicy(ttlMillis: 3600000, expiresAtMs: now + 3600000),
      signedPayload: payloadJson,
      signature: signature,
      hopCount: 0,
      maxHops: 5,
    );

    // 3. Persist to outbox queue with strict priority
    final outboxRecord = OutboxRecord(
      messageId: messageId,
      envelope: envelope,
      priority: severity.level,
      nextAttemptEpochMs: now,
      createdAt: now,
    );
    await database.saveOutboxRecord(outboxRecord);

    // 4. Trigger immediate transmission attempt
    await _processOutboxQueue();

    return incident;
  }

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus newStatus,
    required ConfirmationStatus newConfirmation,
    String? newEventCode,
  }) async {
    final existing = database.getIncident(incidentId);
    if (existing == null) return;

    final newRevision = existing.incidentRevision + 1;
    final updated = existing.createRevision(
      newRevision: newRevision,
      newStatus: newStatus,
      newConfirmationStatus: newConfirmation,
      newType: newEventCode,
    );

    await database.saveIncident(updated);

    // Broadcast revised incident to mesh
    final now = DateTime.now().millisecondsSinceEpoch;
    final payloadJson = jsonEncode(updated.toJson());
    final signature = Envelope.computeSignature(payloadJson, sessionProvider.sharedGroupSecret);

    final envelope = Envelope(
      messageId: const Uuid().v4(),
      sessionId: sessionProvider.currentSessionId,
      originId: sessionProvider.localNodeId,
      intendedRecipients: sessionProvider.authorizedMembers.map((m) => m.id).toList(),
      messageKind: MessageKind.incident,
      originalOccurrenceTime: updated.occurredAt,
      expiryPolicy: ExpiryPolicy(ttlMillis: 3600000, expiresAtMs: now + 3600000),
      signedPayload: payloadJson,
      signature: signature,
      hopCount: 0,
      maxHops: 5,
    );

    await database.saveOutboxRecord(OutboxRecord(
      messageId: envelope.messageId,
      envelope: envelope,
      priority: updated.severity.level,
      nextAttemptEpochMs: now,
      createdAt: now,
    ));

    await _processOutboxQueue();
  }

  @override
  Future<void> handleIncomingIncident(IncidentSnapshot incident) async {
    // Validate newer revision
    final existing = database.getIncident(incident.incidentId);
    if (existing != null && existing.incidentRevision >= incident.incidentRevision) {
      return; // Ignore older or duplicate revision
    }

    // Persist to local database
    await database.saveIncident(incident);

    // Automatically send back exact-revision receipt (STORED)
    final receipt = Receipt(
      messageId: const Uuid().v4(),
      sessionId: sessionProvider.currentSessionId,
      referencedId: incident.incidentId,
      exactRevision: incident.incidentRevision,
      memberId: sessionProvider.localNodeId,
      receiptType: ReceiptType.stored,
      receiptTime: DateTime.now().millisecondsSinceEpoch,
    );

    final receiptPayload = jsonEncode(receipt.toJson());
    final receiptEnvelope = Envelope(
      messageId: receipt.messageId,
      sessionId: sessionProvider.currentSessionId,
      originId: sessionProvider.localNodeId,
      intendedRecipients: [incident.sourceUserId],
      messageKind: MessageKind.receipt,
      originalOccurrenceTime: receipt.receiptTime,
      expiryPolicy: ExpiryPolicy(ttlMillis: 1800000, expiresAtMs: receipt.receiptTime + 1800000),
      signedPayload: receiptPayload,
      signature: Envelope.computeSignature(receiptPayload, sessionProvider.sharedGroupSecret),
      hopCount: 0,
      maxHops: 5,
    );

    // Receipts are prioritized (P1)
    await meshEngine.sendEnvelope(receiptEnvelope, targetPeerId: incident.sourceUserId);
  }

  @override
  Future<void> acknowledgeIncident(String incidentId, int revision) async {
    final incident = database.getIncident(incidentId);
    if (incident == null) return;

    final receipt = Receipt(
      messageId: const Uuid().v4(),
      sessionId: sessionProvider.currentSessionId,
      referencedId: incidentId,
      exactRevision: revision,
      memberId: sessionProvider.localNodeId,
      receiptType: ReceiptType.ackUser,
      receiptTime: DateTime.now().millisecondsSinceEpoch,
    );

    await database.recordReceipt(receipt);
  }

  @override
  Future<void> volunteerHelp(String incidentId, int revision) async {
    final receipt = Receipt(
      messageId: const Uuid().v4(),
      sessionId: sessionProvider.currentSessionId,
      referencedId: incidentId,
      exactRevision: revision,
      memberId: sessionProvider.localNodeId,
      receiptType: ReceiptType.volunteerHelp,
      receiptTime: DateTime.now().millisecondsSinceEpoch,
    );
    await database.recordReceipt(receipt);
  }

  @override
  List<Receipt> getReceiptsForIncident(String incidentId, int revision) {
    return database.getReceiptsFor(incidentId, revision);
  }

  Future<void> _handleIncomingMeshEnvelope(Envelope envelope) async {
    if (envelope.messageKind == MessageKind.incident) {
      try {
        final data = jsonDecode(envelope.signedPayload) as Map<String, dynamic>;
        final incident = IncidentSnapshot.fromJson(data);
        await handleIncomingIncident(incident);
      } catch (_) {}
    } else if (envelope.messageKind == MessageKind.receipt) {
      try {
        final data = jsonDecode(envelope.signedPayload) as Map<String, dynamic>;
        final receipt = Receipt.fromJson(data);
        await database.recordReceipt(receipt);
      } catch (_) {}
    }
  }

  void _startOutboxScheduler() {
    _outboxSchedulerTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _processOutboxQueue();
    });
  }

  Future<void> _processOutboxQueue() async {
    final pending = await database.getPendingOutboxRecords();
    for (final record in pending) {
      final success = await meshEngine.sendEnvelope(record.envelope);
      if (success) {
        await database.markOutboxDelivered(record.messageId);
      } else {
        // Exponential backoff with jitter: 2s, 4s, 8s, up to 60s
        final backoff = ((1 << (record.retryCount.clamp(0, 5))) * 1000) +
            (DateTime.now().millisecondsSinceEpoch % 500);
        await database.updateOutboxRetry(record.messageId, backoff);
      }
    }
  }

  void dispose() {
    _outboxSchedulerTimer?.cancel();
  }
}
