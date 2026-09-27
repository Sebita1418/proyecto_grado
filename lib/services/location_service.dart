import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationStatus {
  permissionNotRequested,
  serviceDisabled,
  permissionGranted,
  permissionDenied,
  permissionDeniedForever,
  coordinatesObtained,
  unexpectedError,
}

class LocationResult {
  const LocationResult(this.status, {this.coordinates});

  final LocationStatus status;
  final LatLng? coordinates;
}

abstract class LocationGateway {
  Future<bool> isServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<LatLng> getPosition();
}

class GeolocatorGateway implements LocationGateway {
  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<LatLng> getPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }
}

class LocationService {
  LocationService({LocationGateway? gateway})
    : _gateway = gateway ?? GeolocatorGateway();

  final LocationGateway _gateway;

  /// Foreground tracking. Cancelling the consumer also cancels Geolocator.
  Stream<LocationResult> watch() async* {
    final initial = await locate();
    yield initial;
    if (initial.status != LocationStatus.coordinatesObtained) return;
    try {
      await for (final position in Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      )) {
        final point = LatLng(position.latitude, position.longitude);
        if (!point.latitude.isFinite ||
            !point.longitude.isFinite ||
            point.latitude.abs() > 90 ||
            point.longitude.abs() > 180) {
          yield const LocationResult(LocationStatus.unexpectedError);
          return;
        }
        yield LocationResult(
          LocationStatus.coordinatesObtained,
          coordinates: point,
        );
      }
    } catch (_) {
      yield const LocationResult(LocationStatus.unexpectedError);
    }
  }

  Future<LocationResult> locate() async {
    try {
      if (!await _gateway.isServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }
      var permission = await _gateway.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _gateway.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationStatus.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.permissionDeniedForever);
      }
      final point = await _gateway.getPosition();
      if (!point.latitude.isFinite ||
          !point.longitude.isFinite ||
          point.latitude.abs() > 90 ||
          point.longitude.abs() > 180) {
        return const LocationResult(LocationStatus.unexpectedError);
      }
      return LocationResult(
        LocationStatus.coordinatesObtained,
        coordinates: point,
      );
    } catch (_) {
      return const LocationResult(LocationStatus.unexpectedError);
    }
  }
}
