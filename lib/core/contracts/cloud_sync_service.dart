import '../models/envelope.dart';

enum CloudSyncStatus {
  unconfigured,
  offline,
  idle,
  syncing,
  error,
}

abstract class CloudSyncService {
  bool get isConfigured;
  CloudSyncStatus get status;
  Stream<CloudSyncStatus> get statusStream;

  Future<void> queueForSync(Envelope envelope);
  Future<bool> attemptSync();
}
