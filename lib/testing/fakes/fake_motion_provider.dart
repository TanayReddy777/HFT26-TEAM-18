import 'dart:async';
import '../../core/contracts/motion_provider.dart';

class FakeMotionProvider implements MotionProvider {
  bool _isAvailable = true;
  final _controller = StreamController<MotionEvent>.broadcast();

  @override
  bool get isSensorAvailable => _isAvailable;

  @override
  Stream<MotionEvent> get motionStream => _controller.stream;

  void emitMotion(double x, double y, double z, double totalG, int timestampMs) {
    _controller.add(MotionEvent(
      x: x,
      y: y,
      z: z,
      totalG: totalG,
      timestampEpochMs: timestampMs,
    ));
  }

  void setSensorAvailable(bool available) {
    _isAvailable = available;
  }

  @override
  Future<void> startListening() async {}

  @override
  Future<void> stopListening() async {}
}
