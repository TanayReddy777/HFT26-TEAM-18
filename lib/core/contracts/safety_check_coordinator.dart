import '../constants/priorities.dart';

enum SafetyCheckTrigger {
  possibleFall,
  contactLoss,
  lowPowerInRedZone,
  manualCheckIn,
}

enum SafetyCheckResponse {
  iAmSafe,
  needHelp,
  snooze,
  timeout,
}

class SafetyCheckRequest {
  final String id;
  final SafetyCheckTrigger trigger;
  final String reason;
  final Priority priority;
  final int deadlineEpochMs;
  final bool allowsSnooze;

  const SafetyCheckRequest({
    required this.id,
    required this.trigger,
    required this.reason,
    required this.priority,
    required this.deadlineEpochMs,
    this.allowsSnooze = false,
  });
}

abstract class SafetyCheckCoordinator {
  SafetyCheckRequest? get currentActiveCheck;
  Stream<SafetyCheckRequest?> get activeCheckStream;

  Future<void> requestSafetyCheck(SafetyCheckRequest request);
  Future<void> respondToCheck(String checkId, SafetyCheckResponse response);
  Future<void> snoozeCheck(String checkId, int snoozeDurationSeconds);
  Future<void> cancelCheck(String checkId);
}
