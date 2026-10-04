import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/mobility/route_incident_analyzer.dart';
import 'package:transporte_inteligente/mobility/route_incident_analysis.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/models/incident_report_draft.dart';
import 'package:transporte_inteligente/models/road_incident_report.dart';
import 'package:transporte_inteligente/models/route_result.dart';

final incidentNow = DateTime.utc(2026, 9, 27, 12);
const incidentOrigin = LatLng(0, 0), incidentDestination = LatLng(0, .02);
RouteResult incidentRoute({
  bool detour = false,
  double seconds = 100,
  double meters = 2200,
}) => RouteResult(
  origin: incidentOrigin,
  destination: incidentDestination,
  points: [
    incidentOrigin,
    if (detour) const LatLng(.003, .01),
    incidentDestination,
  ],
  durationSeconds: seconds,
  distanceMeters: meters,
);
RoadIncidentReport incident({
  String id = 'report',
  IncidentType type = IncidentType.accident,
  LatLng point = const LatLng(0, .01),
  String status = 'activo',
  DateTime? expiresAt,
}) => RoadIncidentReport(
  id: id,
  userId: 'user',
  type: type,
  coordinates: point,
  createdAt: incidentNow.subtract(const Duration(hours: 1)),
  expiresAt: expiresAt ?? incidentNow.add(const Duration(hours: 1)),
  status: status,
);
RouteIncidentAnalysis analyzeIncidents(
  List<RoadIncidentReport> reports, {
  RouteResult? route,
  String id = 'a',
}) => const RouteIncidentAnalyzer().analyze(
  routeId: id,
  geometry: (route ?? incidentRoute()).points,
  reports: reports,
  now: incidentNow,
);

void main() {
  test('segmento largo: reporte en el medio distante de ambos vértices es relevante', () {
    final result = analyzeIncidents([incident()]);
    expect(result.total, 1);
    expect(result.incidents.single.distanceMeters, closeTo(0, .001));
    expect(result.categories[IncidentType.accident], 1);
    expect(result.routeId, 'a');
  });
  for (final entry in {
    80.0: true,
    124.9: true,
    125.1: false,
    200.0: false,
  }.entries) {
    test(
      'distancia perpendicular ${entry.key} m: relevante ${entry.value}',
      () {
        final report = incident(point: LatLng(entry.key / 111195.0802, .01));
        final result = analyzeIncidents([report]);
        expect(result.total, entry.value ? 1 : 0);
        if (entry.value) {
          expect(
            result.incidents.single.distanceMeters,
            closeTo(entry.key, .001),
          );
        }
      },
    );
  }
  test('proyección se limita al segmento, no a la recta infinita', () {
    expect(analyzeIncidents([incident(point: const LatLng(0, .03))]).total, 0);
  });
  test('segmentos repetidos y geometría degenerada no producen NaN', () {
    final result = const RouteIncidentAnalyzer().analyze(
      routeId: 'a',
      geometry: const [LatLng(0, .01), LatLng(0, .01)],
      reports: [incident()],
      now: incidentNow,
    );
    expect(result.incidents.single.distanceMeters, 0);
  });
  test('geometría inválida se rechaza sin falsa ausencia de reportes', () {
    expect(
      () => const RouteIncidentAnalyzer().analyze(
        routeId: 'a',
        geometry: [],
        reports: [],
        now: incidentNow,
      ),
      throwsArgumentError,
    );
  });
  test('cero reportes, colección inmutable y texto explicable', () {
    final result = analyzeIncidents([]);
    expect(result.total, 0);
    expect(result.summary, 'Sin reportes activos próximos');
    expect(result.hasRoadClosure, isFalse);
    expect(() => result.incidents.clear(), throwsUnsupportedError);
  });
  test('múltiples categorías, cierre y deduplicación por identidad', () {
    final result = analyzeIncidents([
      incident(),
      incident(),
      incident(id: 'closure', type: IncidentType.roadClosed),
    ]);
    expect(result.total, 2);
    expect(result.hasRoadClosure, isTrue);
    expect(
      result.summary,
      contains('Cierre vial reportado próximo al recorrido'),
    );
    expect(
      result.categories.keys,
      containsAll([IncidentType.accident, IncidentType.roadClosed]),
    );
  });
  test('expirado, cancelado, coordenadas y fechas inválidas no participan', () {
    final result = analyzeIncidents([
      incident(id: 'expired', expiresAt: incidentNow),
      incident(id: 'cancelled', status: 'cancelado'),
      incident(id: 'invalid', point: LatLng(double.nan, 0)),
      incident(id: '', point: const LatLng(0, .01)),
      incident(
        id: 'bad-dates',
        expiresAt: incidentNow.subtract(const Duration(days: 1)),
      ),
    ]);
    expect(result.total, 0);
  });
  test('dos alternativas analizadas de forma independiente', () {
    final reports = [incident()];
    expect(analyzeIncidents(reports).total, 1);
    expect(
      analyzeIncidents(
        reports,
        route: incidentRoute(detour: true),
        id: 'b',
      ).total,
      0,
    );
  });
  test('expiración cambia análisis con reloj explícito', () {
    final report = incident();
    final result = const RouteIncidentAnalyzer().analyze(
      routeId: 'a',
      geometry: incidentRoute().points,
      reports: [report],
      now: report.expiresAt,
    );
    expect(result.total, 0);
  });

  Future<String> recommend(
    List<RouteResult> routes,
    List<RoadIncidentReport> reports,
  ) async {
    final options = [
      for (var i = 0; i < routes.length; i++)
        RouteOption.fromRouteResult(
          id: '$i',
          mode: TransportMode.driving,
          route: routes[i],
        ),
    ];
    final analyses = {
      for (var i = 0; i < routes.length; i++)
        '$i': analyzeIncidents(reports, route: routes[i], id: '$i'),
    };
    final result = await VehicleRecommendationEngine(clock: () => incidentNow)
        .recommend(
          MobilityContext(
            origin: incidentOrigin,
            destination: incidentDestination,
            allowedModes: {TransportMode.driving},
            requestedAt: incidentNow,
            incidentAnalyses: analyses,
          ),
          options,
        );
    expect(result.alternatives.length, routes.length - 1);
    expect(
      result.recommended.route.durationSeconds,
      routes[int.parse(result.recommended.id)].durationSeconds,
    );
    expect(
      result.reasons.map((r) => r.explanation).join(' '),
      contains('Regla provisional'),
    );
    return result.recommended.id;
  }

  test(
    'prefiere ausencia de cierre dentro de límites, sin alterar minutos',
    () async {
      expect(
        await recommend(
          [
            incidentRoute(),
            incidentRoute(detour: true, seconds: 120, meters: 3000),
          ],
          [incident(type: IncidentType.roadClosed)],
        ),
        '1',
      );
    },
  );
  test('menor exposición decide entre alternativas comparables', () async {
    expect(
      await recommend(
        [
          incidentRoute(),
          incidentRoute(detour: true, seconds: 120, meters: 3000),
        ],
        [incident()],
      ),
      '1',
    );
  });
  for (final metrics in [(126.0, 3000.0), (120.0, 3301.0)]) {
    test('no favorece desvío desproporcionado: $metrics', () async {
      expect(
        await recommend(
          [
            incidentRoute(),
            incidentRoute(
              detour: true,
              seconds: metrics.$1,
              meters: metrics.$2,
            ),
          ],
          [incident(type: IncidentType.roadClosed)],
        ),
        '0',
      );
    });
  }
  test('límites inclusivos de duración y distancia', () async {
    expect(
      await recommend(
        [
          incidentRoute(),
          incidentRoute(detour: true, seconds: 125, meters: 3300),
        ],
        [incident()],
      ),
      '1',
    );
  });
  test('misma exposición conserva duración como criterio', () async {
    expect(
      await recommend(
        [incidentRoute(seconds: 110), incidentRoute(seconds: 100)],
        [incident()],
      ),
      '1',
    );
  });
  test('misma exposición y duración conserva distancia y orden', () async {
    expect(
      await recommend(
        [incidentRoute(meters: 2300), incidentRoute(meters: 2200)],
        [incident()],
      ),
      '1',
    );
    expect(await recommend([incidentRoute(), incidentRoute()], []), '0');
  });
  test('cierre tiene prioridad sobre conteo, sin afirmar bloqueo', () async {
    final reports = [
      incident(type: IncidentType.roadClosed),
      incident(id: 'b1', point: const LatLng(.003, .01)),
      incident(id: 'b2', point: const LatLng(.003, .01)),
    ];
    expect(
      await recommend([
        incidentRoute(),
        incidentRoute(detour: true, seconds: 120, meters: 3000),
      ], reports),
      '1',
    );
  });
}
