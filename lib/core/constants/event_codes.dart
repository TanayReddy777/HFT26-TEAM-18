/// Shared Event Code Registry for the ResQ Emergency System.
/// Defines standardized codes across all modules for state tracking, receipts, and notifications.
class EventCodes {
  // Group Proximity & Tracking
  static const String separationWarning = 'SEPARATION_WARNING';
  static const String separationCritical = 'SEPARATION_CRITICAL';
  static const String peerLocationStale = 'PEER_LOCATION_STALE';
  static const String contactCheckUnanswered = 'CONTACT_CHECK_UNANSWERED';

  // Boundary & Meeting Point
  static const String boundaryExit = 'BOUNDARY_EXIT';
  static const String boundaryReturn = 'BOUNDARY_RETURN';
  static const String meetingPointStored = 'MEETING_POINT_STORED';
  static const String meetingPointRemoved = 'MEETING_POINT_REMOVED';

  // Motion & Fall Detection
  static const String possibleFall = 'POSSIBLE_FALL';
  static const String userConfirmedSafe = 'USER_CONFIRMED_SAFE';
  static const String userRequestedHelp = 'USER_REQUESTED_HELP';

  // Power & Battery State
  static const String lowPowerAlert = 'LOW_POWER_ALERT';
  static const String criticalLowPower = 'CRITICAL_LOW_POWER';

  // Emergency SOS Lifecycle
  static const String confirmedSos = 'CONFIRMED_SOS';
  static const String unconfirmedSos = 'UNCONFIRMED_SOS';
  static const String noResponse = 'NO_RESPONSE';
  static const String incidentResolved = 'INCIDENT_RESOLVED';

  static const List<String> allCodes = [
    separationWarning,
    separationCritical,
    peerLocationStale,
    contactCheckUnanswered,
    boundaryExit,
    boundaryReturn,
    meetingPointStored,
    meetingPointRemoved,
    possibleFall,
    userConfirmedSafe,
    userRequestedHelp,
    lowPowerAlert,
    criticalLowPower,
    confirmedSos,
    unconfirmedSos,
    noResponse,
    incidentResolved,
  ];

  static bool isValid(String code) => allCodes.contains(code);
}
