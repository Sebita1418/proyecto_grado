import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/navigation/navigation_session.dart';
import 'package:transporte_inteligente/navigation/trip_summary.dart';
import 'package:transporte_inteligente/services/location_service.dart';

import 'navigation_session_test.dart' show route;

class RetryLocation extends LocationService {
  final streams = <StreamController<LocationResult>>[];
  @override
  Stream<LocationResult> watch() {
    final stream = StreamController<LocationResult>();
    streams.add(stream);
    return stream.stream;
  }

  Future<void> close() async {
    for (final stream in streams) {
      await stream.close();
    }
  }
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('viaje conserva selección, tiempos y resumen idempotente sin inventar recorrido', () async {
    var now = DateTime.utc(2026, 9, 28, 10);
    final gps = RetryLocation();
    final session = NavigationSession(gps, now: () => now);
    expect(session.tripState, TripState.idle);
    const context = TripRouteContext(
      originLabel: 'Origen',
      alternativeIndex: 1,
      alternativeCount: 3,
    );
    session.start(route, 'Destino', context: context);
    expect(session.tripState, TripState.active);
    session.togglePanel();
    session.pauseFollowing();
    gps.streams.single.add(
      const LocationResult(
        LocationStatus.coordinatesObtained,
        coordinates: LatLng(0, .01),
      ),
    );
    await flush();
    expect(session.progress, closeTo(.5, .001));
    expect(session.projectedDistance, closeTo(session.geometryDistance / 2, 1));
    expect(session.remainingDistance, closeTo(session.geometryDistance / 2, 1));
    expect(session.panelExpanded, isFalse);
    now = now.add(const Duration(minutes: 12));
    session.finish();
    expect(session.tripState, TripState.completed);
    expect(gps.streams.single.hasListener, isFalse);
    final summary = session.summary!;
    expect(summary.elapsed, const Duration(minutes: 12));
    expect(summary.context, same(context));
    expect(summary.selectedRoute, same(route));
    expect(summary.reachedDestination, isFalse);
    expect(summary.hadPosition, isTrue);
    session.finish();
    expect(session.summary, same(summary));
    session.start(route, 'Otro destino');
    expect(session.summary, isNull);
    expect(session.panelExpanded, isTrue);
    session.dispose();
    await gps.close();
  });

  test(
    'error GPS permite retry explícito sin duplicar streams ni borrar contexto',
    () async {
      final gps = RetryLocation();
      final session = NavigationSession(gps)..start(route, 'Destino');
      gps.streams.single.add(
        const LocationResult(
          LocationStatus.coordinatesObtained,
          coordinates: LatLng(0, .01),
        ),
      );
      await flush();
      final start = session.startedAt;
      gps.streams.single.addError(StateError('offline'));
      await flush();
      expect(session.isActive, isTrue);
      expect(session.canRetryGps, isTrue);
      expect(gps.streams.single.hasListener, isFalse);
      await Future.wait([session.retryGps(), session.retryGps()]);
      expect(gps.streams, hasLength(2));
      expect(session.startedAt, start);
      expect(session.selectedRoute, same(route));
      expect(session.currentPosition, const LatLng(0, .01));
      gps.streams.last.add(
        const LocationResult(
          LocationStatus.coordinatesObtained,
          coordinates: LatLng(0, .015),
        ),
      );
      await flush();
      expect(session.gpsState, TripGpsState.available);
      expect(session.progress, closeTo(.75, .001));
      session.dispose();
      expect(gps.streams.last.hasListener, isFalse);
      await gps.close();
    },
  );

  test('GPS impreciso y obsoleto no avanzan ni disparan recálculo', () async {
    final gps = RetryLocation();
    var reroutes = 0;
    final session = NavigationSession(
      gps,
      reroute: ({required origin, required destination}) async {
        reroutes++;
        return route;
      },
    )..start(route, 'Destino');
    final date = DateTime.utc(2026);
    gps.streams.single.add(
      LocationResult(
        LocationStatus.coordinatesObtained,
        coordinates: const LatLng(0, .01),
        recordedAt: date,
        accuracyMeters: 10,
      ),
    );
    await flush();
    for (var i = 0; i < 4; i++) {
      gps.streams.single.add(
        LocationResult(
          LocationStatus.coordinatesObtained,
          coordinates: const LatLng(.01, .019),
          recordedAt: date.add(Duration(seconds: i + 1)),
          accuracyMeters: 120,
        ),
      );
    }
    gps.streams.single.add(
      LocationResult(
        LocationStatus.coordinatesObtained,
        coordinates: const LatLng(0, 0),
        recordedAt: date.subtract(const Duration(seconds: 1)),
      ),
    );
    await flush();
    expect(session.progress, closeTo(.5, .001));
    expect(session.currentPosition, const LatLng(0, .01));
    expect(reroutes, 0);
    session.finish();
    session.dispose();
    await gps.close();
  });

  test('retry seguido de finish o dispose no reabre GPS', () async {
    for (final dispose in [false, true]) {
      final gps = RetryLocation();
      final session = NavigationSession(gps)..start(route, 'Destino');
      gps.streams.single.add(
        const LocationResult(LocationStatus.permissionDenied),
      );
      await flush();
      final retry = session.retryGps();
      if (dispose) {
        session.dispose();
      } else {
        session.finish();
      }
      await retry;
      expect(gps.streams, hasLength(1));
      if (!dispose) session.dispose();
      await gps.close();
    }
  });
}
