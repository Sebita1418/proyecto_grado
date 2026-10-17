import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/navigation/navigation_camera.dart';
import 'package:transporte_inteligente/navigation/navigation_session.dart';
import 'package:transporte_inteligente/services/location_service.dart';

import 'navigation_session_test.dart' show TrackingLocation, route;

LocationResult fix({
  double lat = 0,
  double lon = .005,
  double accuracy = 5,
  double speed = 10,
  double heading = 90,
  double headingAccuracy = 5,
}) => LocationResult(
  LocationStatus.coordinatesObtained,
  coordinates: LatLng(lat, lon),
  accuracyMeters: accuracy,
  speedMetersPerSecond: speed,
  headingDegrees: heading,
  headingAccuracyDegrees: headingAccuracy,
);
void main() {
  test('GNSS fiable dirige cámara 2D y preserva zoom configurable', () {
    final camera = NavigationCamera(zoom: 17);
    expect(camera.accept(fix()), isTrue);
    expect(camera.position, const LatLng(0, .005));
    expect(camera.rotation, -90);
    expect(camera.zoom, 17);
  });
  test('rotación usa camino corto al cruzar norte', () {
    expect(NavigationCamera.angularDelta(-359, -1), 358 - 360);
    expect(NavigationCamera.angularDelta(-1, -359), 2);
    expect(NavigationCamera.angularDelta(0, -90), -90);
  });
  test('detenido conserva rumbo y evita jitter de posición', () {
    final camera = NavigationCamera()..accept(fix());
    camera.accept(fix(lon: .00501, speed: 0, heading: 250));
    expect(camera.rotation, -90);
    expect(camera.position, const LatLng(0, .005));
  });
  test('rumbo inestable o metadatos ausentes no giran', () {
    final camera = NavigationCamera()..accept(fix());
    for (final value in [
      fix(speed: 1, heading: 180),
      fix(accuracy: 30, heading: 180),
      fix(headingAccuracy: 50, heading: 180),
      fix(heading: double.nan),
      const LocationResult(
        LocationStatus.coordinatesObtained,
        coordinates: LatLng(0, .006),
      ),
    ]) {
      expect(camera.accept(value), isTrue);
      expect(camera.rotation, -90);
    }
  });
  test('GPS impreciso conserva último encuadre y recupera siguiente fix', () {
    final camera = NavigationCamera()..accept(fix());
    expect(camera.accept(fix(lon: .015, accuracy: 100)), isFalse);
    expect(camera.position, const LatLng(0, .005));
    expect(camera.accept(fix(lon: .006, heading: 120)), isTrue);
    expect(camera.position, const LatLng(0, .006));
    expect(camera.rotation, -120);
  });
  test('GPS impreciso no dispara llegada ni recálculo, seguimiento pausa y recentra', () async {
    final gps = TrackingLocation();
    var reroutes = 0;
    final session = NavigationSession(
      gps,
      reroute: ({required origin, required destination}) async {
        reroutes++;
        return route;
      },
    );
    session.start(route, 'Destino');
    gps.updates.add(fix());
    await Future<void>.delayed(Duration.zero);
    final progress = session.progress;
    for (var i = 0; i < 3; i++) {
      gps.updates.add(fix(lat: .02, lon: .02, accuracy: 100));
    }
    await Future<void>.delayed(Duration.zero);
    expect(session.progress, progress);
    expect(session.arrived, isFalse);
    expect(reroutes, 0);
    expect(session.notice, contains('GPS impreciso'));
    session.pauseFollowing();
    expect(session.following, isFalse);
    session.recenter();
    expect(session.following, isTrue);
    gps.updates.add(fix(lon: .006));
    await Future<void>.delayed(Duration.zero);
    expect(session.notice, isNull);
    session.dispose();
    await gps.updates.close();
  });
}
