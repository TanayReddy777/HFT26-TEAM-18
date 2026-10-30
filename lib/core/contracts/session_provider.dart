import '../models/member.dart';

abstract class SessionProvider {
  String get currentSessionId;
  String get localNodeId;
  String get localDisplayName;
  String get sharedGroupSecret;
  bool get isLeader;

  List<Member> get authorizedMembers;
  Member? get primaryBuddy;

  Stream<List<Member>> get membersStream;
  Stream<String> get sessionStateStream;

  Future<void> createSession({required String displayName, required String groupSecret});
  Future<void> joinSession({required String sessionId, required String displayName, required String groupSecret});
  Future<void> setPrimaryBuddy(String memberId);
  Future<void> updateMemberLocation(String memberId, double lat, double lon, double accuracy, int fixTime);
  Future<void> endSession();
}
