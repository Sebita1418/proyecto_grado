import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/route_incident_analysis.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/models/incident_report_draft.dart';
import 'package:transporte_inteligente/models/route_insight.dart';

import '../mobility/route_incident_analysis_test.dart'
    show
        incident,
        incidentNow,
        incidentOrigin,
        incidentDestination,
        incidentRoute;

RouteIncidentAnalysis snapshot(String id, [IncidentType? type]) =>
    RouteIncidentAnalysis(
      routeId: id,
      evaluatedAt: incidentNow,
      incidents: [
        if (type != null) RouteIncidentProximity(incident(type: type), 30),
      ],
    );

Future<RouteInsight> insightFor({
  List<RouteIncidentAnalysis> analyses = const [],
  bool single = false,
}) async {
  final recommendation = await VehicleRecommendationEngine().recommend(
    MobilityContext(
      origin: incidentOrigin,
      destination: incidentDestination,
      allowedModes: {TransportMode.driving},
      requestedAt: incidentNow,
      incidentAnalyses: {for (final a in analyses) a.routeId: a},
    ),
    [
      RouteOption.fromRouteResult(
        id: 'a',
        mode: TransportMode.driving,
        route: incidentRoute(seconds: 720, meters: 7400),
      ),
      if (!single)
        RouteOption.fromRouteResult(
          id: 'b',
          mode: TransportMode.driving,
          route: incidentRoute(seconds: 780, meters: 7100),
        ),
    ],
  );
  return RouteInsight(recommendation: recommendation, analyses: analyses);
}

void main() {
  test('sin incidentes muestra ausencia solo con evidencia', () async {
    final insight = await insightFor(analyses: [snapshot('a'), snapshot('b')]);
    expect(insight.highlights, contains('Sin reportes próximos'));
    expect(insight.highlights, contains('Sin cierres reportados próximos'));
    expect(insight.reportCount, 0);
    expect(insight.duration, '12 min');
    expect(insight.distance, '7,4 km');
    expect(insight.highlights.length, lessThanOrEqualTo(3));
    expect(insight.highlights.toSet().length, insight.highlights.length);
  });
  test('reporte próximo se muestra sin atribuir un cierre', () async {
    final insight = await insightFor(
      single: true,
      analyses: [snapshot('a', IncidentType.accident)],
    );
    expect(insight.reportCount, 1);
    expect(insight.closureCount, 0);
    expect(insight.highlights, contains('1 reporte vial próximo'));
  });
  test('cierre próximo se cuenta y no afirma ausencia de cierres', () async {
    final insight = await insightFor(
      single: true,
      analyses: [snapshot('a', IncidentType.roadClosed)],
    );
    expect(insight.closureCount, 1);
    expect(insight.highlights, contains('1 cierre reportado próximo'));
    expect(
      insight.highlights,
      isNot(contains('Sin cierres reportados próximos')),
    );
  });
  test('varias alternativas explica variables disponibles', () async {
    final insight = await insightFor(analyses: [snapshot('a'), snapshot('b')]);
    expect(insight.alternativeCount, 2);
    expect(insight.comparison, contains('Alternativas comparadas: 2'));
    expect(insight.comparison, contains('reportes viales activos'));
  });
  test('una alternativa no inventa comparación', () async {
    final insight = await insightFor(single: true);
    expect(insight.alternativeCount, 1);
    expect(insight.comparison, contains('no hubo comparación'));
    expect(insight.highlights.join(' '), isNot(contains('Duración mínima')));
  });
  test('duración explica el motivo real del motor', () async {
    final insight = await insightFor();
    expect(insight.recommendation.recommended.id, 'a');
    expect(
      insight.highlights,
      contains('Duración mínima entre alternativas comparadas'),
    );
    expect(insight.explanations.single, startsWith('Menor duración estimada'));
    expect(insight.comparison, isNot(contains('reportes viales activos')));
  });
  test(
    'menor exposición cambia sugerencia sin inventar menor duración',
    () async {
      final insight = await insightFor(
        analyses: [snapshot('a', IncidentType.accident), snapshot('b')],
      );
      expect(insight.recommendation.recommended.id, 'b');
      expect(insight.duration, '13 min');
      expect(
        insight.explanations.join(' '),
        contains('sin reportes viales activos próximos'),
      );
      expect(
        insight.explanations.join(' '),
        isNot(contains('Menor duración estimada')),
      );
    },
  );
  test('cierre influye y conserva explicación explícita del motor', () async {
    final insight = await insightFor(
      analyses: [snapshot('a', IncidentType.roadClosed), snapshot('b')],
    );
    expect(insight.recommendation.recommended.id, 'b');
    expect(
      insight.explanations.join(' '),
      contains('Se prioriza una alternativa sin cierres'),
    );
  });
  test(
    'datos ausentes o de otra ruta no generan razones sin evidencia',
    () async {
      final insight = await insightFor(analyses: [snapshot('otra')]);
      expect(insight.reportCount, isNull);
      expect(insight.closureCount, isNull);
      expect(
        insight.highlights,
        contains('Condiciones reportadas no disponibles'),
      );
      expect(insight.highlights.join(' '), isNot(contains('Sin cierres')));
      expect(insight.highlights.join(' '), isNot(contains('Sin reportes')));
      expect(
        insight.explanations,
        insight.recommendation.reasons.map((r) => r.explanation).toList(),
      );
    },
  );
}
