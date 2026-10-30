import 'dart:async';
import '../../core/contracts/safety_check_coordinator.dart';
import '../../core/constants/priorities.dart';
import '../../core/models/member.dart';

class ContactLossDetector {
  final SafetyCheckCoordinator safetyCoordinator;
  final int contactLossTimeoutSeconds;

  final Map<String, bool> _activePrompts = {};

  ContactLossDetector({
    required this.safetyCoordinator,
    this.contactLossTimeoutSeconds = 120,
  });

  void checkBuddyFreshness(Member? buddy) {
    if (buddy == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastSeen = buddy.lastSeenEpochMs;
    final elapsedSeconds = (now - lastSeen) / 1000;

    if (elapsedSeconds > contactLossTimeoutSeconds) {
      if (!(_activePrompts[buddy.id] ?? false)) {
        _activePrompts[buddy.id] = true;
        _triggerSafetyPrompt(buddy);
      }
    } else {
      // Reconnected within timeout window
      if (_activePrompts[buddy.id] ?? false) {
        _activePrompts[buddy.id] = false;
      }
    }
  }

  void _triggerSafetyPrompt(Member buddy) {
    final checkId = 'CHECK_CONTACT_LOSS_${buddy.id}_${DateTime.now().millisecondsSinceEpoch}';
    final request = SafetyCheckRequest(
      id: checkId,
      trigger: SafetyCheckTrigger.contactLoss,
      reason: 'Lost contact with buddy ${buddy.displayName}. Are you safe? (Buddy status unknown)',
      priority: Priority.p1Urgent,
      deadlineEpochMs: DateTime.now().millisecondsSinceEpoch + 45000, // 45s countdown
      allowsSnooze: true,
    );

    safetyCoordinator.requestSafetyCheck(request);
  }
}
