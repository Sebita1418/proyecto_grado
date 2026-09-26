import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/navigation/navigation_progress.dart';
import 'package:transporte_inteligente/navigation/navigation_session.dart';
import 'package:transporte_inteligente/services/location_service.dart';

const route = RouteResult(
  origin: LatLng(0, 0),
  destination: LatLng(0, .02),
  points: [LatLng(0, 0), LatLng(0, .005), LatLng(0, .02)],
  distanceMeters: 2200,
  durationSeconds: 600,
);

class TrackingLocation extends LocationService {
  final updates = StreamController<LocationResult>();
  @override
  Stream<LocationResult> watch() => updates.stream;
  @override
  Future<LocationResult> locate() async => const LocationResult(
    LocationStatus.coordinatesObtained,
    coordinates: LatLng(0, 0),
  );
  void position(LatLng point) => updates.add(
    LocationResult(LocationStatus.coordinatesObtained, coordinates: point),
  );
}

void main() {
  test(
    'proyección ponderada por distancia y separación sin perder geometría',
    () {
      final geometry = NavigationProgress(route.points);
      final result = geometry.project(const LatLng(0, .01));
      expect(result.progress, closeTo(.5, .001));
      expect(result.distanceToRoute, 0);
      expect(result.traveled.last.latitude, 0);
      expect(result.traveled.last.longitude, closeTo(.01, 1e-10));
      expect(result.remaining.first, result.traveled.last);
      expect(result.remaining.last, route.destination);
      expect(geometry.project(const LatLng(0, -.01)).progress, 0);
      expect(geometry.project(const LatLng(0, .03)).progress, 1);
      expect(
        NavigationProgress([route.origin, route.origin, route.destination])
            .project(const LatLng(0, .01))
            .progress,
        closeTo(.5, .001),
      );
    },
  );

  test('start, GPS, desvío, llegada y finish cancelan seguimiento', () async {
    final gps = TrackingLocation();
    final session = NavigationSession(gps);
    expect(session.start(route, 'Destino'), isTrue);
    expect(session.start(route, 'Duplicado'), isFalse);
    expect(session.route, same(route));
    expect(session.progress, 0);
    gps.position(const LatLng(0, .01));
    await Future<void>.delayed(Duration.zero);
    expect(session.progress, closeTo(.5, .001));
    expect(session.remainingDistance, closeTo(1100, 2));
    expect(session.remainingDuration, closeTo(300, 1));
    gps.position(const LatLng(.01, .019));
    await Future<void>.delayed(Duration.zero);
    expect(session.offRoute, isTrue);
    expect(session.progress, closeTo(.5, .001));
    expect(session.arrived, isFalse);
    session.pauseFollowing();
    expect(session.following, isFalse);
    session.recenter();
    expect(session.following, isTrue);
    gps.position(route.destination);
    await Future<void>.delayed(Duration.zero);
    expect(session.arrived, isTrue);
    expect(session.remainingDistance, 0);
    session.finish();
    expect(session.isActive, isFalse);
    expect(gps.updates.hasListener, isFalse);
    session.dispose();
    await gps.updates.close();
  });

  for (final status in [
    LocationStatus.permissionDenied,
    LocationStatus.permissionDeniedForever,
    LocationStatus.serviceDisabled,
  ]) {
    test('estado $status es visible y cancela el stream', () async {
      final gps = TrackingLocation();
      final session = NavigationSession(gps)..start(route, 'Destino');
      gps.updates.add(LocationResult(status));
      await Future<void>.delayed(Duration.zero);
      expect(session.notice, isNotNull);
      expect(session.progress, 0);
      expect(gps.updates.hasListener, isFalse);
      session.finish();
      session.dispose();
      await gps.updates.close();
    });
  }

  test('error de stream y dispose liberan listeners', () async {
    final gps = TrackingLocation();
    final session = NavigationSession(gps)..start(route, 'Destino');
    gps.updates.addError(StateError('GPS unavailable'));
    await Future<void>.delayed(Duration.zero);
    expect(session.notice, contains('GPS'));
    expect(gps.updates.hasListener, isFalse);
    session.dispose();
    await gps.updates.close();
    final otherGps = TrackingLocation();
    final other = NavigationSession(otherGps)..start(route, 'Destino');
    other.dispose();
    expect(otherGps.updates.hasListener, isFalse);
    await otherGps.updates.close();
  });

  test('rechaza geometría inválida sin suscribirse', () async {
    final gps = TrackingLocation();
    final session = NavigationSession(gps);
    expect(
      session.start(
        const RouteResult(
          origin: LatLng(0, 0),
          destination: LatLng(0, 0),
          points: [LatLng(0, 0), LatLng(0, 0)],
          distanceMeters: 10,
          durationSeconds: 10,
        ),
        'Destino',
      ),
      isFalse,
    );
    expect(gps.updates.hasListener, isFalse);
    session.dispose();
    unawaited(gps.updates.close());
  });
}
