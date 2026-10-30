import 'dart:async';
import '../../core/contracts/location_provider.dart';
import '../../core/models/location_snapshot.dart';
import '../../core/models/power_state.dart';

class FakeLocationProvider implements LocationProvider {
  LocationSnapshot? _latestFix;
  bool _hasPermission = true;
  bool _isServiceEnabled = true;

  final _controller = StreamController<LocationSnapshot>.broadcast();

  @override
  LocationSnapshot? get latestFix => _latestFix;

  @override
  bool get hasPermission => _hasPermission;

  @override
  bool get isLocationServiceEnabled => _isServiceEnabled;

  @override
  Stream<LocationSnapshot> get locationStream => _controller.stream;

  void setFix(double lat, double lon, double accuracy, {bool isHistorical = false}) {
    _latestFix = LocationSnapshot(
      latitude: lat,
      longitude: lon,
      accuracyMeters: accuracy,
      recordedAt: DateTime.now().millisecondsSinceEpoch,
      isHistorical: isHistorical,
    );
    _controller.add(_latestFix!);
  }

  void setPermissions(bool granted, bool serviceEnabled) {
    _hasPermission = granted;
    _isServiceEnabled = serviceEnabled;
  }

  @override
  Future<void> requestPermissions() async {
    _hasPermission = true;
  }

  @override
  Future<void> startTracking(PowerPolicy policy) async {}

  @override
  Future<void> updatePolicy(PowerPolicy policy) async {}

  @override
  Future<void> stopTracking() async {}
}
