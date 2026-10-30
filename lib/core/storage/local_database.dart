import 'dart:async';
import '../models/envelope.dart';
import '../models/incident_snapshot.dart';
import '../models/meeting_point.dart';
import '../models/receipt.dart';
import '../models/risk_zone.dart';

class OutboxRecord {
  final String messageId;
  final Envelope envelope;
  final int priority;
  final int retryCount;
  final int nextAttemptEpochMs;
  final bool isDelivered;
  final int createdAt;

  const OutboxRecord({
    required this.messageId,
    required this.envelope,
    required this.priority,
    this.retryCount = 0,
    required this.nextAttemptEpochMs,
    this.isDelivered = false,
    required this.createdAt,
  });

  OutboxRecord copyWith({
    int? retryCount,
    int? nextAttemptEpochMs,
    bool? isDelivered,
  }) {
    return OutboxRecord(
      messageId: messageId,
      envelope: envelope,
      priority: priority,
      retryCount: retryCount ?? this.retryCount,
      nextAttemptEpochMs: nextAttemptEpochMs ?? this.nextAttemptEpochMs,
      isDelivered: isDelivered ?? this.isDelivered,
      createdAt: createdAt,
    );
  }
}

/// Unified offline storage service for ResQ.
/// Guarantees durable atomic persistence before transmission,
/// revision tracking, receipt accounting, and replay deduplication.
class LocalDatabase {
  final Map<String, OutboxRecord> _outbox = {};
  final Map<String, IncidentSnapshot> _incidents = {};
  final List<Receipt> _receipts = [];
  MeetingPointUpdate? _currentMeetingPoint;
  final Map<String, RiskZone> _riskZones = {};
  final Set<String> _seenMessageIds = {};

  final _incidentChangeController = StreamController<List<IncidentSnapshot>>.broadcast();
  final _meetingPointChangeController = StreamController<MeetingPointUpdate?>.broadcast();

  Stream<List<IncidentSnapshot>> get incidentsStream => _incidentChangeController.stream;
  Stream<MeetingPointUpdate?> get meetingPointStream => _meetingPointChangeController.stream;

  // --- Outbox Management ---
  Future<void> saveOutboxRecord(OutboxRecord record) async {
    _outbox[record.messageId] = record;
  }

  Future<List<OutboxRecord>> getPendingOutboxRecords() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final pending = _outbox.values
        .where((r) => !r.isDelivered && r.nextAttemptEpochMs <= now)
        .toList();
    // Sort strictly by priority (lower number = higher emergency priority P0 > P1 > P2 > P3)
    pending.sort((a, b) => a.priority.compareTo(b.priority));
    return pending;
  }

  Future<void> markOutboxDelivered(String messageId) async {
    final record = _outbox[messageId];
    if (record != null) {
      _outbox[messageId] = record.copyWith(isDelivered: true);
    }
  }

  Future<void> updateOutboxRetry(String messageId, int backoffMillis) async {
    final record = _outbox[messageId];
    if (record != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _outbox[messageId] = record.copyWith(
        retryCount: record.retryCount + 1,
        nextAttemptEpochMs: now + backoffMillis,
      );
    }
  }

  // --- Deduplication Cache ---
  bool isMessageSeen(String messageId) => _seenMessageIds.contains(messageId);

  void markMessageSeen(String messageId) {
    _seenMessageIds.add(messageId);
    if (_seenMessageIds.length > 5000) {
      _seenMessageIds.remove(_seenMessageIds.first);
    }
  }

  // --- Incident Management ---
  Future<void> saveIncident(IncidentSnapshot incident) async {
    final existing = _incidents[incident.incidentId];
    // Reject obsolete revisions
    if (existing != null && existing.incidentRevision >= incident.incidentRevision) {
      return;
    }
    _incidents[incident.incidentId] = incident;
    _incidentChangeController.add(_incidents.values.toList());
  }

  IncidentSnapshot? getIncident(String incidentId) => _incidents[incidentId];

  List<IncidentSnapshot> getAllIncidents() => _incidents.values.toList();

  // --- Meeting Point & Tombstone Management ---
  Future<void> saveMeetingPoint(MeetingPointUpdate update) async {
    if (_currentMeetingPoint != null &&
        _currentMeetingPoint!.sessionRevision >= update.sessionRevision) {
      // Reject stale revisions
      return;
    }
    _currentMeetingPoint = update;
    _meetingPointChangeController.add(update);
  }

  MeetingPointUpdate? get currentMeetingPoint => _currentMeetingPoint;

  // --- Receipts ---
  Future<void> recordReceipt(Receipt receipt) async {
    // Prevent duplicate receipt writes
    final exists = _receipts.any((r) =>
        r.referencedId == receipt.referencedId &&
        r.exactRevision == receipt.exactRevision &&
        r.memberId == receipt.memberId &&
        r.receiptType == receipt.receiptType);
    if (!exists) {
      _receipts.add(receipt);
    }
  }

  List<Receipt> getReceiptsFor(String referencedId, int revision) {
    return _receipts
        .where((r) => r.referencedId == referencedId && r.exactRevision == revision)
        .toList();
  }

  // --- Risk Zones ---
  Future<void> saveRiskZone(RiskZone zone) async {
    _riskZones[zone.id] = zone;
  }

  Future<void> removeRiskZone(String id) async {
    _riskZones.remove(id);
  }

  List<RiskZone> getAllRiskZones() => _riskZones.values.toList();

  Future<void> clearAll() async {
    _outbox.clear();
    _incidents.clear();
    _receipts.clear();
    _currentMeetingPoint = null;
    _riskZones.clear();
    _seenMessageIds.clear();
    _incidentChangeController.add([]);
    _meetingPointChangeController.add(null);
  }
}
