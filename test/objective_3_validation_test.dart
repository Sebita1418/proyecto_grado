import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/mobility/analytics/historical_departure_guidance.dart';
import 'package:transporte_inteligente/mobility/analytics/mobility_analytics.dart';
import 'package:transporte_inteligente/mobility/decision/current_mobility_decision_adapter.dart';
import 'package:transporte_inteligente/mobility/decision/departure_time_context.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_decision_coordinator.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/mobility_recommendation.dart';
import 'package:transporte_inteligente/mobility/route_incident_analyzer.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/services/mode_routing_service.dart';
import 'package:transporte_inteligente/services/osrm_routing_service.dart';

import 'mobility/analytics/historical_departure_guidance_test.dart' as history;
import 'mobility/route_incident_analysis_test.dart' as spatial;
import 'mobility/vehicle_recommendation_engine_test.dart' as vehicle;
import 'services/mode_routing_service_test.dart' as modes;
import 'support/boundary_fixtures.dart';

// All inputs are deterministic TEST FIXTURES. No live OSRM or Supabase data,
// no database writes, no measurements of actual traffic or user outcomes.
final evidence = <Map<String, Object?>>[];
void record(String id, Map<String, Object?> input, Object output) {
  evidence.add({
    'id': id,
    'input': input,
    'output': output,
    'status': 'PASS',
    'dataNature': 'synthetic fixture; production components executed',
  });
}

Map<String, Object?> recommendation(MobilityRecommendation value) => {
  'selected': value.recommended.id,
  'seconds': value.recommended.route.durationSeconds,
  'meters': value.recommended.route.distanceMeters,
  'alternatives': value.alternatives.map((o) => o.id).toList(),
  'reasons': value.reasons.map((r) => r.explanation).toList(),
};
Map<String, Object?> historical(HistoricalDepartureGuidance value) => {
  'status': value.status.name,
  'reason': value.reason,
  'observations': value.totalObservations,
  'completeDays': value.completeDays,
  'weekdayOccurrences': value.weekdayOccurrences,
  'selectedHour': value.selectedHour,
  'selectedHourObservations': value.selectedMetric.observations,
  'lowerHours': value.lowerActivity.map((m) => m.hour).toList(),
  'lowerCounts': value.lowerActivity.map((m) => m.observations).toList(),
};
void main() {
  tearDownAll(() {
    final outputDirectory =
        Platform.environment['OE3_EVIDENCE_DIR'] ??
        'docs/evidence/objective-3/2026-10-15';
    final file = File('$outputDirectory/scenarios.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
    );
  });
  final engine = VehicleRecommendationEngine(clock: () => vehicle.instant);
  test(
    'OE3-01 mismo OD delega tres modos y rechaza transporte público',
    () async {
      final requests = <String>[];
      OsrmRoutingService service(String graph, int seconds) =>
          OsrmRoutingService(
            endpoint: Uri.parse('https://fixture.invalid/$graph'),
            boundaryService: legacyTestBoundary(),
            client: MockClient((request) async {
              requests.add(request.url.toString());
              return http.Response(
                jsonEncode({
                  'code': 'Ok',
                  'routes': [modes.route(seconds.toDouble(), 1000)],
                }),
                200,
              );
            }),
          );
      final car = service('car', 120),
          foot = service('foot', 900),
          bike = service('bike', 300);
      final routing = ModeRoutingService(
        driving: car,
        walking: foot,
        cycling: bike,
      );
      final results = <String, Object>{};
      for (final entry in {
        TransportMode.driving: 120,
        TransportMode.walking: 900,
        TransportMode.cycling: 300,
      }.entries) {
        final route = (await routing.route(
          RoutingRequest(
            origin: vehicle.origin,
            destination: vehicle.destination,
            mode: entry.key,
          ),
        )).single;
        expect(route.durationSeconds, entry.value);
        expect(route.origin, vehicle.origin);
        expect(route.destination, vehicle.destination);
        results[entry.key.name] = {
          'seconds': route.durationSeconds,
          'meters': route.distanceMeters,
        };
      }
      await expectLater(
        () => routing.route(
          RoutingRequest(
            origin: vehicle.origin,
            destination: vehicle.destination,
            mode: TransportMode.publicTransport,
          ),
        ),
        throwsA(isA<OsrmRoutingException>()),
      );
      expect(requests.length, 3);
      expect(requests[0], contains('/car/route/'));
      expect(requests[1], contains('/foot/route/'));
      expect(requests[2], contains('/bike/route/'));
      record(
        'OE3-01',
        {
          'origin': [7.1, -73.1],
          'destination': [7.2, -73.2],
          'mockHttp': true,
        },
        {
          'routes': results,
          'requests': requests,
          'publicTransport': 'unsupported',
          'crossModeRecommendation': 'not implemented',
        },
      );
      routing.dispose();
      car.dispose();
      foot.dispose();
      bike.dispose();
    },
  );
  for (final change in [false, true]) {
    test(
      'OE3-0${change ? 3 : 2} duración cambia sugerencia con mismo OD',
      () async {
        final options = [
          vehicle.option('a', 180, 1000),
          vehicle.option('b', change ? 240 : 120, 2000),
          vehicle.option('c', 200, 500),
        ];
        final result = await engine.recommend(vehicle.context(), options);
        expect(result.recommended.id, change ? 'a' : 'b');
        expect(result.reasons, isNotEmpty);
        record(change ? 'OE3-03' : 'OE3-02', {
          'a': [180, 1000],
          'b': [change ? 240 : 120, 2000],
          'c': [200, 500],
          'units': ['seconds', 'meters'],
        }, recommendation(result));
      },
    );
  }
  test('OE3-04 empate en duración se explica por distancia', () async {
    final result = await engine.recommend(vehicle.context(), [
      vehicle.option('a', 120, 2000),
      vehicle.option('b', 120, 1000),
    ]);
    expect(result.recommended.id, 'b');
    expect(
      result.reasons.any((r) => r.explanation.contains('desempate')),
      isTrue,
    );
    record('OE3-04', {
      'a': [120, 2000],
      'b': [120, 1000],
    }, recommendation(result));
  });
  for (final reportsPresent in [false, true]) {
    test(
      'OE3-0${reportsPresent ? 6 : 5} snapshot de incidentes cambia sugerencia',
      () async {
        final options = [
          RouteOption.fromRouteResult(
            id: 'a',
            mode: TransportMode.driving,
            route: spatial.incidentRoute(),
            source: 'fixture',
          ),
          RouteOption.fromRouteResult(
            id: 'b',
            mode: TransportMode.driving,
            route: spatial.incidentRoute(
              detour: true,
              seconds: 120,
              meters: 2400,
            ),
            source: 'fixture',
          ),
        ];
        final analyses = {
          for (final option in options)
            option.id: const RouteIncidentAnalyzer().analyze(
              routeId: option.id,
              geometry: option.route.points,
              reports: reportsPresent ? [spatial.incident()] : [],
              now: spatial.incidentNow,
            ),
        };
        final context = MobilityContext(
          origin: spatial.incidentOrigin,
          destination: spatial.incidentDestination,
          allowedModes: {TransportMode.driving},
          requestedAt: spatial.incidentNow,
          incidentAnalyses: analyses,
        );
        final result = await engine.recommend(context, options);
        expect(analyses['a']!.total, reportsPresent ? 1 : 0);
        expect(analyses['b']!.total, 0);
        expect(result.recommended.id, reportsPresent ? 'b' : 'a');
        record(
          reportsPresent ? 'OE3-06' : 'OE3-05',
          {
            'a': [100, 2200],
            'b': [120, 2400],
            'origin': [0, 0],
            'destination': [0, .02],
            'detourVertex': [.003, .01],
            'reportPoint': reportsPresent ? [0, .01] : null,
            'reportPersistence': 'in-memory fixture, NOT a real DB insertion',
          },
          {
            'recommendation': recommendation(result),
            'nearbyCounts': {
              for (final entry in analyses.entries)
                entry.key: entry.value.total,
            },
          },
        );
      },
    );
  }
  test('OE3-07 preferencia sin driving no produce vehículo ni comparación multimodal', () async {
    await expectLater(
      engine.recommend(vehicle.context({TransportMode.walking}), [
        vehicle.option('car', 120, 1000),
      ]),
      throwsA(isA<NoEligibleVehicleRouteException>()),
    );
    record(
      'OE3-07',
      {
        'allowedModes': ['walking'],
        'candidateMode': 'driving',
      },
      {
        'result': 'NoEligibleVehicleRouteException',
        'meaning': 'no eligible vehicle; no invented multimodal winner',
      },
    );
  });
  test('OE3-08 falta de snapshot no equivale a cero incidentes', () async {
    final result = await engine.recommend(vehicle.context(), [
      vehicle.option('a', 100, 1000),
      vehicle.option('b', 120, 1100),
    ]);
    expect(result.recommended.id, 'a');
    expect(
      result.reasons.any((r) => r.explanation.contains('sin reportes')),
      isFalse,
    );
    record('OE3-08', {
      'incidentAnalyses': 'missing',
      'a': [100, 1000],
      'b': [120, 1100],
    }, recommendation(result));
  });
  test('OE3-09 historial insuficiente se abstiene de orientar', () {
    final result = history.evaluate(
      AnalyticsBatch(
        history.denseBatch().observations.take(99),
        evaluatedAt: history.end,
      ),
    );
    expect(result.status, HistoricalGuidanceStatus.insufficient);
    expect(result.lowerActivity, isEmpty);
    record('OE3-09', {
      'queryStart': history.query.start.toIso8601String(),
      'queryEndExclusive': history.query.end.toIso8601String(),
      'rows': 99,
    }, historical(result));
  });
  test(
    'OE3-10 historial suficiente solo describe menor actividad observada',
    () {
      final batch = history.denseBatch();
      final result = history.evaluate(batch);
      expect(result.status, HistoricalGuidanceStatus.observed);
      expect(result.lowerActivity.single.hour, 8);
      expect(result.totalObservations, 1316);
      record('OE3-10', {
        'rows': batch.observations.length,
        'queryStart': history.query.start.toIso8601String(),
        'queryEndExclusive': history.query.end.toIso8601String(),
        'selectedDeparture': history.selected.toIso8601String(),
        'generator': '28 days; 1 report/hour at :10; extra report at :20 except civil hour 8; synthetic only',
      }, historical(result));
    },
  );
  test('OE3-11 cambiar registros cambia franja; lote parcial se abstiene', () {
    final shifted = history.denseBatch().observations.map((o) {
      final hour = BogotaCalendar.fields(o.createdAt).hour;
      return history.row(
        o.createdAt.add(
          Duration(
            hours: hour == 8
                ? 8
                : hour == 16
                ? -8
                : 0,
          ),
        ),
      );
    });
    final result = history.evaluate(
      AnalyticsBatch(shifted, evaluatedAt: history.end),
    );
    final partial = history.evaluate(history.denseBatch(truncated: true));
    expect(result.lowerActivity.single.hour, 16);
    expect(partial.status, HistoricalGuidanceStatus.partial);
    expect(partial.lowerActivity, isEmpty);
    record(
      'OE3-11',
      {
        'mutation':
            'swap civil hours 8 and 16; separately truncate original batch',
      },
      {'shifted': historical(result), 'partial': historical(partial)},
    );
  });
  test('OE3-12 Programar no produce recomendación futura', () async {
    final options = [vehicle.option('a', 120, 1000)];
    final recommendationValue = await engine.recommend(
      vehicle.context(),
      options,
    );
    final context = const CurrentMobilityDecisionAdapter().build(
      trip: vehicle.context(),
      departure: DepartureTimeContext.scheduled(
        vehicle.instant.add(const Duration(days: 1)),
      ),
      routes: options,
    );
    final result = const MobilityDecisionCoordinator().decide(
      context,
      vehicleRecommendation: recommendationValue,
    );
    expect(result.hasRecommendation, isFalse);
    record(
      'OE3-12',
      {
        'departure': 'scheduled, instant + 1 day',
        'currentVehicleRouteExists': true,
      },
      {
        'hasRecommendation': result.hasRecommendation,
        'reason': result.noRecommendationReason?.name,
      },
    );
  });
}
