import '../models/meeting_point.dart';
import '../models/receipt.dart';

abstract class MeetingPointRepository {
  MeetingPointUpdate? get currentMeetingPoint;
  Stream<MeetingPointUpdate?> get meetingPointStream;
  List<Receipt> get receipts;

  Future<void> saveMeetingPoint(MeetingPointUpdate update);
  Future<void> removeMeetingPoint(String pointId, int newRevision, String updatedBy);
  Future<void> recordReceipt(Receipt receipt);
  int getReceiptCountForRevision(int revision);
}
