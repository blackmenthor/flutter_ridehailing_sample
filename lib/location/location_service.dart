import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

class LocationService {
  final Function(LocationData) onLocationChanged;

  LocationService({
    required this.onLocationChanged,
  });

  Location location = new Location();
  bool _serviceEnabled = false;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;

  bool _serviceStarted = false;

  Future<void> init() async {
    if (_serviceStarted) return;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData? firstLocation = await location.getLocation();
    onLocationChanged(firstLocation);
    location.onLocationChanged.listen((LocationData currentLocation) async {
      // Use current location
      _locationData = await location.getLocation();
      if (_locationData != null) onLocationChanged(_locationData!);
    });
    location.enableBackgroundMode(enable: true);

    _serviceStarted = true;
  }

  static Future<List<DocumentSnapshot<Object>>?> getUserByLocationNearby(
    double latitude,
    double longitude, [
    double distanceInMile = 10,
  ]) async {
    // ~1 mile of lat and lon in degrees
    final lat = 0.0144927536231884;
    final lon = 0.0181818181818182;

    final lowerLat = latitude - (lat * distanceInMile);
    final lowerLong = longitude - (lon * distanceInMile);

    final greaterLat = latitude + (lat * distanceInMile);
    final greaterLong = longitude + (lon * distanceInMile);

    final lesserGeoPoint = GeoPoint(lowerLat, lowerLong);
    final greaterGeoPoint = GeoPoint(greaterLat, greaterLong);

    final doc = FirebaseFirestore.instance.collection('user-data');
    final query = doc
        .where('last-location', isGreaterThanOrEqualTo: lesserGeoPoint)
        .where('last-location', isLessThanOrEqualTo: greaterGeoPoint);
    final queryObj = await query.get();

    return queryObj.docs;
  }
}
