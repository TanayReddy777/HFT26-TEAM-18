import '../../core/models/receipt.dart';

enum DeliveryStage {
  createdStored,
  queued,
  submittedToTransport,
  receivedByRelay,
  deliveredToRecipient,
  recipientUserAcknowledged,
  volunteeredHelp,
  resolved,
  expiredTransmission,
  failedTransmission,
}

class MemberDeliveryStatus {
  final String memberId;
  final DeliveryStage stage;
  final int lastUpdatedEpochMs;

  const MemberDeliveryStatus({
    required this.memberId,
    required this.stage,
    required this.lastUpdatedEpochMs,
  });
}

class DeliverySummary {
  final String messageOrIncidentId;
  final int exactRevision;
  final int totalIntendedRecipients;
  final int acknowledgedCount;
  final List<String> acknowledgedMemberNames;
  final List<String> pendingMemberNames;
  final bool isFullyAcknowledged;

  const DeliverySummary({
    required this.messageOrIncidentId,
    required this.exactRevision,
    required this.totalIntendedRecipients,
    required this.acknowledgedCount,
    required this.acknowledgedMemberNames,
    required this.pendingMemberNames,
    required this.isFullyAcknowledged,
  });
}

class DeliveryTracker {
  final Map<String, Map<String, MemberDeliveryStatus>> _statusMap = {};

  void recordStage({
    required String messageId,
    required String memberId,
    required DeliveryStage stage,
  }) {
    _statusMap.putIfAbsent(messageId, () => {})[memberId] = MemberDeliveryStatus(
      memberId: memberId,
      stage: stage,
      lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  DeliverySummary computeSummary({
    required String messageId,
    required int revision,
    required List<String> intendedMemberIds,
    required Map<String, String> memberNameMap,
    required List<Receipt> receipts,
  }) {
    final ackedMemberIds = receipts
        .where((r) => r.referencedId == messageId && r.exactRevision == revision)
        .map((r) => r.memberId)
        .toSet();

    final ackedNames = <String>[];
    final pendingNames = <String>[];

    for (final memberId in intendedMemberIds) {
      final name = memberNameMap[memberId] ?? memberId;
      if (ackedMemberIds.contains(memberId)) {
        ackedNames.add(name);
      } else {
        pendingNames.add(name);
      }
    }

    return DeliverySummary(
      messageOrIncidentId: messageId,
      exactRevision: revision,
      totalIntendedRecipients: intendedMemberIds.length,
      acknowledgedCount: ackedNames.length,
      acknowledgedMemberNames: ackedNames,
      pendingMemberNames: pendingNames,
      isFullyAcknowledged: intendedMemberIds.isNotEmpty &&
          ackedNames.length >= intendedMemberIds.length,
    );
  }
}
