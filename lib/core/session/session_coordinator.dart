import 'dart:async';
import 'package:uuid/uuid.dart';
import '../contracts/session_provider.dart';
import '../models/member.dart';

class SessionCoordinator implements SessionProvider {
  String _currentSessionId = '';
  String _localNodeId = const Uuid().v4();
  String _localDisplayName = 'User_${DateTime.now().millisecondsSinceEpoch % 1000}';
  String _sharedGroupSecret = 'resq_default_offline_mesh_key';
  bool _isLeader = false;
  String? _primaryBuddyId;

  final Map<String, Member> _members = {};

  final _membersStreamController = StreamController<List<Member>>.broadcast();
  final _sessionStateStreamController = StreamController<String>.broadcast();

  @override
  String get currentSessionId => _currentSessionId;

  @override
  String get localNodeId => _localNodeId;

  @override
  String get localDisplayName => _localDisplayName;

  @override
  String get sharedGroupSecret => _sharedGroupSecret;

  @override
  bool get isLeader => _isLeader;

  @override
  List<Member> get authorizedMembers => _members.values.toList();

  @override
  Member? get primaryBuddy => _primaryBuddyId != null ? _members[_primaryBuddyId] : null;

  @override
  Stream<List<Member>> get membersStream => _membersStreamController.stream;

  @override
  Stream<String> get sessionStateStream => _sessionStateStreamController.stream;

  @override
  Future<void> createSession({
    required String displayName,
    required String groupSecret,
  }) async {
    _currentSessionId = 'SESSION_${DateTime.now().millisecondsSinceEpoch}';
    _localDisplayName = displayName;
    _sharedGroupSecret = groupSecret;
    _isLeader = true;

    final selfMember = Member(
      id: _localNodeId,
      displayName: _localDisplayName,
      publicKey: 'pk_${_localNodeId.substring(0, 8)}',
      isLeader: true,
      lastSeenEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    _members[_localNodeId] = selfMember;
    _sessionStateStreamController.add('SESSION_ACTIVE');
    _notifyMembers();
  }

  @override
  Future<void> joinSession({
    required String sessionId,
    required String displayName,
    required String groupSecret,
  }) async {
    _currentSessionId = sessionId;
    _localDisplayName = displayName;
    _sharedGroupSecret = groupSecret;
    _isLeader = false;

    final selfMember = Member(
      id: _localNodeId,
      displayName: _localDisplayName,
      publicKey: 'pk_${_localNodeId.substring(0, 8)}',
      isLeader: false,
      lastSeenEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    _members[_localNodeId] = selfMember;
    _sessionStateStreamController.add('SESSION_ACTIVE');
    _notifyMembers();
  }

  void enrollPeer({
    required String memberId,
    required String displayName,
    required String publicKey,
    bool isLeader = false,
  }) {
    if (!_members.containsKey(memberId)) {
      _members[memberId] = Member(
        id: memberId,
        displayName: displayName,
        publicKey: publicKey,
        isLeader: isLeader,
        lastSeenEpochMs: DateTime.now().millisecondsSinceEpoch,
      );
      if (_primaryBuddyId == null && memberId != _localNodeId) {
        _primaryBuddyId = memberId;
      }
      _notifyMembers();
    }
  }

  @override
  Future<void> setPrimaryBuddy(String memberId) async {
    if (_members.containsKey(memberId)) {
      _primaryBuddyId = memberId;
      for (final key in _members.keys) {
        _members[key] = _members[key]!.copyWith(isPrimaryBuddy: key == memberId);
      }
      _notifyMembers();
    }
  }

  @override
  Future<void> updateMemberLocation(
    String memberId,
    double lat,
    double lon,
    double accuracy,
    int fixTime,
  ) async {
    final member = _members[memberId];
    if (member != null) {
      _members[memberId] = member.copyWith(
        lastLatitude: lat,
        lastLongitude: lon,
        lastAccuracyMeters: accuracy,
        lastFixEpochMs: fixTime,
        lastSeenEpochMs: DateTime.now().millisecondsSinceEpoch,
      );
      _notifyMembers();
    }
  }

  @override
  Future<void> endSession() async {
    _currentSessionId = '';
    _isLeader = false;
    _primaryBuddyId = null;
    _members.clear();
    _sessionStateStreamController.add('SESSION_ENDED');
    _notifyMembers();
  }

  void _notifyMembers() {
    _membersStreamController.add(_members.values.toList());
  }
}
