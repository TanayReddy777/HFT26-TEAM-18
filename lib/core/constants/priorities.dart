/// Canonical Priority definitions for message scheduling, queuing, and transmission.
enum Priority {
  /// P0: Explicit user SOS, severe life-threatening trauma, or configured auto SOS escalation.
  /// Precedes all other traffic; never downgraded.
  p0Critical(0, 'P0_CRITICAL_SOS'),

  /// P1: Urgent help requests, unconfirmed possible falls, urgent safety checks.
  p1Urgent(1, 'P1_URGENT_HELP'),

  /// P2: Hazard and safety warnings, ordinary low-power alerts.
  p2Warning(2, 'P2_WARNING_HAZARD'),

  /// P3: Normal chat messages, routine status updates.
  p3Normal(3, 'P3_NORMAL_INFO');

  final int level;
  final String label;

  const Priority(this.level, this.label);

  static Priority fromLevel(int level) {
    switch (level) {
      case 0:
        return Priority.p0Critical;
      case 1:
        return Priority.p1Urgent;
      case 2:
        return Priority.p2Warning;
      case 3:
      default:
        return Priority.p3Normal;
    }
  }

  bool operator <(Priority other) => level < other.level;
  bool operator <=(Priority other) => level <= other.level;
  bool operator >(Priority other) => level > other.level;
  bool operator >=(Priority other) => level >= other.level;
}
