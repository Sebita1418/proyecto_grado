import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/services/route_traffic_service.dart';

import '../support/boundary_fixtures.dart';

final trafficNow = DateTime.utc(2026, 10, 16, 23);
const trafficPoint = LatLng(7.1, -73.1);
final trafficRoute = RouteResult(
  origin: const LatLng(7.1, -73.101),
  destination: const LatLng(7.1, -73.099),
  points: const [LatLng(7.1, -73.101), trafficPoint, LatLng(7.1, -73.099)],
  durationSeconds: 100,
  distanceMeters: 220,
);
// Controlled TEST response; not a TomTom observation.
Map<String, dynamic> trafficFixture() => {
  'provider': 'TomTom',
  'endpoint': RouteTrafficObservation.endpoint,
  'queriedAt': trafficNow.toIso8601String(),
  'queryCoordinate': {'latitude': 7.1, 'longitude': -73.1},
  'flowSegmentData': {
    'currentSpeed': 20,
    'freeFlowSpeed': 40,
    'currentTravelTime': 40,
    'freeFlowTravelTime': 20,
    'confidence': .9,
    'roadClosure': false,
    'coordinates': {
      'coordinate': [
        {'latitude': 7.1, 'longitude': -73.1005},
        {'latitude': 7.1, 'longitude': -73.0995},
      ],
    },
  },
};

void main() {
  test(
    'disabled traffic never calls provider or requires credentials',
    () async {
      final service = RouteTrafficService(
        enabled: false,
        query: (_) => throw StateError('must not call'),
      );
      final results = await service.inspect([trafficRoute]);
      expect(results.single.observation, isNull);
      expect(results.single.status, contains('BLOCKED'));
    },
  );
  test('valid fragment exposes metrics, provenance and spatial offset without route ETA', () {
    final result = RouteTrafficService.validate(
      trafficFixture(),
      trafficRoute,
      trafficPoint,
      trafficNow,
    );
    expect(result.observation!.currentSpeed, 20);
    expect(result.observation!.confidence, .9);
    expect(result.observation!.maximumOffsetMeters, closeTo(0, .001));
    expect(result.explanation, contains('no confirma carril ni sentido'));
    expect(trafficRoute.durationSeconds, 100);
  });
  for (final condition in [
    'low-confidence',
    'stale',
    'future',
    'wrong-point',
    'wrong-provider',
    'far-segment',
    'invalid-number',
    'closure',
  ]) {
    test('rejects $condition without substituting zero traffic', () {
      final payload = trafficFixture();
      final flow = payload['flowSegmentData'] as Map;
      switch (condition) {
        case 'low-confidence':
          flow['confidence'] = .79;
        case 'stale':
          payload['queriedAt'] = trafficNow
              .subtract(const Duration(seconds: 121))
              .toIso8601String();
        case 'future':
          payload['queriedAt'] = trafficNow
              .add(const Duration(seconds: 1))
              .toIso8601String();
        case 'wrong-point':
          payload['queryCoordinate'] = {'latitude': 7.2, 'longitude': -73.1};
        case 'wrong-provider':
          payload['provider'] = 'unknown';
        case 'far-segment':
          flow['coordinates'] = {
            'coordinate': [
              {'latitude': 7.2, 'longitude': -73.1},
              {'latitude': 7.2, 'longitude': -73.099},
            ],
          };
        case 'invalid-number':
          flow['currentSpeed'] = double.nan;
        case 'closure':
          flow['roadClosure'] = true;
      }
      expect(
        RouteTrafficService.validate(
          payload,
          trafficRoute,
          trafficPoint,
          trafficNow,
        ).observation,
        isNull,
      );
    });
  }
  test('cache expires and revalidates geometry; request cap and errors are explicit', () async {
    var calls = 0;
    var now = trafficNow;
    final service = RouteTrafficService(
      enabled: true,
      boundary: legacyTestBoundary(),
      clock: () => now,
      query: (_) async {
        calls++;
        final response = trafficFixture();
        response['queriedAt'] = now.toIso8601String();
        return response;
      },
    );
    final result = await service.inspect(List.filled(4, trafficRoute));
    expect(calls, 1);
    expect(result.take(3).every((r) => r.observation != null), isTrue);
    expect(result.last.status, contains('límite'));
    now = now.add(const Duration(seconds: 61));
    await service.inspect([trafficRoute]);
    expect(calls, 2);
    final errors = RouteTrafficService(
      enabled: true,
      boundary: legacyTestBoundary(),
      query: (_) async => throw Exception('private provider failure'),
    );
    final failed = await errors.inspect([trafficRoute]);
    expect(failed.single.observation, isNull);
    expect(
      failed.single.explanation,
      isNot(contains('private provider failure')),
    );
  });
}
