import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/traffic_aware_recommendation_engine.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/services/osrm_routing_service.dart';
import 'package:transporte_inteligente/services/route_traffic_service.dart';

import '../support/boundary_fixtures.dart';
import 'route_incident_analysis_test.dart' as fixtures;

void main() {
  final output = <Map<String, Object?>>[];
  final directory = Platform.environment['OE3_EVIDENCE_DIR'];
  final engine = TrafficAwareRecommendationEngine(
    engine: VehicleRecommendationEngine(clock: () => fixtures.incidentNow),
    traffic: RouteTrafficService(enabled: false),
  );
  Future<void> evaluate(
    String id,
    MobilityContext context,
    List<RouteOption> options,
    String nature,
  ) async {
    final baseline = options.first;
    final watch = Stopwatch()..start();
    final result = await engine.recommend(context, options);
    watch.stop();
    final selected = result.recommended.route, base = baseline.route;
    output.add({
      'id': id,
      'dataNature': nature,
      'origin': [context.origin.latitude, context.origin.longitude],
      'destination': [
        context.destination.latitude,
        context.destination.longitude,
      ],
      'allowedModes': context.allowedModes.map((m) => m.name).toList(),
      'requestedAt': context.requestedAt.toIso8601String(),
      'baselinePolicy':
          'first OSRM alternative supplied, not observed fastest travel',
      'baselineId': baseline.id,
      'recommendedId': result.recommended.id,
      'alternatives': options
          .map(
            (o) => {
              'id': o.id,
              'mode': o.mode.name,
              'distanceMeters': o.route.distanceMeters,
              'durationSeconds': o.route.durationSeconds,
              'activeNearbyReports': context.incidentAnalyses[o.id]?.total,
            },
          )
          .toList(),
      'durationDifferenceSeconds':
          selected.durationSeconds - base.durationSeconds,
      'durationDifferencePercent': base.durationSeconds == 0
          ? null
          : 100 *
                (selected.durationSeconds - base.durationSeconds) /
                base.durationSeconds,
      'distanceDifferenceMeters': selected.distanceMeters - base.distanceMeters,
      'distanceDifferencePercent': base.distanceMeters == 0
          ? null
          : 100 *
                (selected.distanceMeters - base.distanceMeters) /
                base.distanceMeters,
      'algorithmMicroseconds': watch.elapsedMicroseconds,
      'trafficObservedRouteCoverage': 0,
      'contextualScore': null,
      'explainable': result.reasons.isNotEmpty,
      'reasons': result.reasons.map((r) => r.explanation).toList(),
    });
    expect(
      result.reasons.any((r) => r.explanation.contains('BLOCKED')),
      isTrue,
    );
  }

  tearDownAll(() async {
    if (directory == null) return;
    final folder = Directory(directory);
    await folder.create(recursive: true);
    await File('$directory/comparisons.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(output));
    final lines = [
      'id,dataNature,baselineId,recommendedId,durationDifferenceSeconds,durationDifferencePercent,distanceDifferenceMeters,distanceDifferencePercent,algorithmMicroseconds,trafficObservedRouteCoverage,explainable',
    ];
    for (final row in output) {
      lines.add(
        [
          'id',
          'dataNature',
          'baselineId',
          'recommendedId',
          'durationDifferenceSeconds',
          'durationDifferencePercent',
          'distanceDifferenceMeters',
          'distanceDifferencePercent',
          'algorithmMicroseconds',
          'trafficObservedRouteCoverage',
          'explainable',
        ].map((k) => '"${row[k].toString().replaceAll('"', '""')}"').join(','),
      );
    }
    await File('$directory/comparisons.csv')
        .writeAsString('${lines.join('\n')}\n');
  });
  for (final withIncident in [false, true]) {
    test(
      'quantitative controlled incident=$withIncident preserves provider metrics',
      () async {
        final routes = [
          fixtures.incidentRoute(),
          fixtures.incidentRoute(detour: true, seconds: 120, meters: 2400),
        ];
        final options = [
          for (var i = 0; i < routes.length; i++)
            RouteOption.fromRouteResult(
              id: 'osrm-$i',
              mode: TransportMode.driving,
              route: routes[i],
              source: 'osrm',
            ),
        ];
        final reports = withIncident ? [fixtures.incident()] : <Never>[];
        final context = MobilityContext(
          origin: fixtures.incidentOrigin,
          destination: fixtures.incidentDestination,
          allowedModes: {TransportMode.driving},
          requestedAt: fixtures.incidentNow,
          incidentAnalyses: {
            for (var i = 0; i < routes.length; i++)
              'osrm-$i': fixtures.analyzeIncidents(
                reports,
                route: routes[i],
                id: 'osrm-$i',
              ),
          },
        );
        await evaluate(
          'controlled-${withIncident ? 'incident' : 'clear'}',
          context,
          options,
          'B: synthetic routes and incident fixture',
        );
        expect(
          output.last['recommendedId'],
          withIncident ? 'osrm-1' : 'osrm-0',
        );
      },
    );
  }
  test(
    'missing snapshots keep baseline and do not claim no incidents',
    () async {
      final route = fixtures.incidentRoute();
      final context = MobilityContext(
        origin: route.origin,
        destination: route.destination,
        allowedModes: {TransportMode.driving},
        requestedAt: fixtures.incidentNow,
      );
      await evaluate('controlled-missing', context, [
        RouteOption.fromRouteResult(
          id: 'osrm-0',
          mode: TransportMode.driving,
          route: route,
          source: 'osrm',
        ),
      ], 'B: synthetic route, missing incident data');
      expect(
        (output.last['reasons'] as List).any(
          (s) => s.toString().contains('sin reportes'),
        ),
        isFalse,
      );
    },
  );
  test(
    'captured real provider routes pass production parser and recommendation',
    () async {
      final fixtureDirectory =
          directory ??
          'docs/evidence/fdc125/04-objetivo-3/intervention-2026-10-16';
      final requestsFile = File('$fixtureDirectory/provider-requests.json');
      expect(
        requestsFile.existsSync(),
        isTrue,
        reason: 'Captured real evidence is required',
      );
      final records = jsonDecode(await requestsFile.readAsString()) as List;
      var evaluated = 0;
      for (final record in records) {
        if (record['status'] != 200 ||
            record['code'] != 'Ok' ||
            record['routeCount'] == 0) {
          continue;
        }
        final bytes = await File('$fixtureDirectory/${record['file']}')
            .readAsString();
        final origin = LatLng(
          record['origin']['latitude'],
          record['origin']['longitude'],
        );
        final destination = LatLng(
          record['destination']['latitude'],
          record['destination']['longitude'],
        );
        final routing = OsrmRoutingService(
          client: MockClient(
            (_) async => http.Response.bytes(utf8.encode(bytes), 200),
          ),
          endpoint: Uri.parse('https://fixture.local'),
          boundaryService: legacyTestBoundary(),
        );
        final routes = await routing.routeAlternatives(
          origin: origin,
          destination: destination,
        );
        routing.dispose();
        if (record['mode'] != 'driving') continue;
        final options = [
          for (var i = 0; i < routes.length; i++)
            RouteOption.fromRouteResult(
              id: 'osrm-$i',
              mode: TransportMode.driving,
              route: routes[i],
              source: 'osrm',
            ),
        ];
        await evaluate(
          record['id'],
          MobilityContext(
            origin: origin,
            destination: destination,
            allowedModes: {TransportMode.driving},
            requestedAt: DateTime.parse(record['queriedAt']),
          ),
          options,
          'A: captured real OSRM; replayed HTTP; incident and traffic unavailable',
        );
        evaluated++;
      }
      expect(evaluated, greaterThan(0));
    },
  );
}
