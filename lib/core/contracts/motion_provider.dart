class MotionEvent {
  final double x;
  final double y;
  final double z;
  final double totalG;
  final int timestampEpochMs;

  const MotionEvent({
    required this.x,
    required this.y,
    required this.z,
    required this.totalG,
    required this.timestampEpochMs,
  });
}

abstract class MotionProvider {
  bool get isSensorAvailable;
  Stream<MotionEvent> get motionStream;

  Future<void> startListening();
  Future<void> stopListening();
}
