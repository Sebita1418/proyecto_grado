import '../mobility/mobility_recommendation.dart';
import '../mobility/route_incident_analysis.dart';
import 'incident_report_draft.dart';

/// Presentation of an existing decision and its matching incident snapshot.
/// Does not rank routes, analyze geometry or fetch data.
class RouteInsight {
  RouteInsight({
    required this.recommendation,
    List<RouteIncidentAnalysis> analyses = const [],
  }) : analysis = analyses
           .where((item) => item.routeId == recommendation.recommended.id)
           .firstOrNull;

  final MobilityRecommendation recommendation;
  final RouteIncidentAnalysis? analysis;

  int get alternativeCount => recommendation.alternatives.length + 1;
  String get duration =>
      '${(recommendation.recommended.route.durationSeconds / 60).ceil()} min';
  String get distance =>
      '${(recommendation.recommended.route.distanceMeters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  int? get reportCount => analysis?.total;
  int? get closureCount => analysis == null
      ? null
      : analysis!.categories[IncidentType.roadClosed] ?? 0;

  List<String> get highlights => [
    if (recommendation.reasons.any(
      (r) => r.factor == RecommendationFactor.duration,
    ))
      recommendation.reasons.any(
            (r) => r.factor == RecommendationFactor.conditions,
          )
          ? 'Duración mínima entre finalistas con igual exposición'
          : 'Duración mínima entre alternativas comparadas',
    if (analysis != null) ...[
      if (closureCount == 0) 'Sin cierres reportados próximos',
      if (closureCount! > 0)
        '$closureCount ${closureCount == 1 ? 'cierre reportado próximo' : 'cierres reportados próximos'}',
      if (reportCount == 0) 'Sin reportes próximos',
      if (reportCount! > 0)
        '$reportCount ${reportCount == 1 ? 'reporte vial próximo' : 'reportes viales próximos'}',
    ] else
      'Condiciones reportadas no disponibles',
  ];

  String get comparison => alternativeCount == 1
      ? 'Se recibió una sola alternativa; no hubo comparación entre rutas.'
      : 'Alternativas comparadas: $alternativeCount. '
            '${recommendation.reasons.any((r) => r.factor == RecommendationFactor.conditions) ? 'Se consideraron duración, distancia y reportes viales activos próximos al recorrido.' : 'Se consideraron duración y distancia.'}';

  List<String> get explanations =>
      recommendation.reasons.map((reason) => reason.explanation).toList();
}
