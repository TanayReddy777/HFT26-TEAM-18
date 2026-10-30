import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../contracts/location_provider.dart';
import '../models/location_snapshot.dart';
import '../models/power_state.dart';

class LocationCoordinator implements LocationProvider {
  LocationSnapshot? _latestFix;
  bool _hasPermission = false;
  bool _isLocationServiceEnabled = false;
  bool _isTracking = false;
  PowerPolicy _currentPolicy = PowerPolicy.normal;

  final List<LocationSnapshot> _boundedHistory = [];
  static const int maxHistorySize = 10;

  final _locationController = StreamController<LocationSnapshot>.broadcast();
  StreamSubscription<Position>? _positionSubscription;

  @override
  LocationSnapshot? get latestFix => _latestFix;

  @override
  bool get hasPermission => _hasPermission;

  @override
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;

  @override
  Stream<LocationSnapshot> get locationStream => _locationController.stream;

  List<LocationSnapshot> get boundedHistory => List.unmodifiable(_boundedHistory);

  @override
  Future<void> requestPermissions() async {
    _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    _hasPermission = (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse);
  }

  @override
  Future<void> startTracking(PowerPolicy policy) async {
    _currentPolicy = policy;
    _isTracking = true;

    await _positionSubscription?.cancel();

    // Map PowerPolicy to appropriate LocationSettings interval and distance filter
    final locationSettings = LocationSettings(
      accuracy: policy.level == PowerPolicyLevel.criticalPower
          ? LocationAccuracy.low
          : (policy.level == PowerPolicyLevel.lowPower
              ? LocationAccuracy.medium
              : LocationAccuracy.high),
      distanceFilter: policy.level == PowerPolicyLevel.criticalPower ? 50 : 10,
      timeLimit: Duration(seconds: policy.locationIntervalSeconds),
    );

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) {
          final snapshot = LocationSnapshot(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracyMeters: position.accuracy,
            recordedAt: position.timestamp.millisecondsSinceEpoch,
            isHistorical: false,
          );
          _recordFix(snapshot);
        },
        onError: (e) {
          // Keep old fix as historical if stream faults
          if (_latestFix != null) {
            _latestFix = LocationSnapshot(
              latitude: _latestFix!.latitude,
              longitude: _latestFix!.longitude,
              accuracyMeters: _latestFix!.accuracyMeters,
              recordedAt: _latestFix!.recordedAt,
              isHistorical: true,
            );
          }
        },
      );
    } catch (_) {
      // In headless/simulator environments without native geolocator, safely fallback
    }
  }

  void injectFixForTesting(LocationSnapshot snapshot) {
    _recordFix(snapshot);
  }

  void _recordFix(LocationSnapshot snapshot) {
    _latestFix = snapshot;
    _boundedHistory.add(snapshot);
    if (_boundedHistory.length > maxHistorySize) {
      _boundedHistory.removeAt(0);
    }
    _locationController.add(snapshot);
  }

  @override
  Future<void> updatePolicy(PowerPolicy policy) async {
    _currentPolicy = policy;
    if (_isTracking) {
      await startTracking(policy);
    }
  }

  @override
  Future<void> stopTracking() async {
    _isTracking = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
