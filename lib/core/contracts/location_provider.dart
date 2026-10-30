import '../models/location_snapshot.dart';
import '../models/power_state.dart';

abstract class LocationProvider {
  LocationSnapshot? get latestFix;
  bool get hasPermission;
  bool get isLocationServiceEnabled;

  Stream<LocationSnapshot> get locationStream;

  Future<void> requestPermissions();
  Future<void> startTracking(PowerPolicy policy);
  Future<void> updatePolicy(PowerPolicy policy);
  Future<void> stopTracking();
}
