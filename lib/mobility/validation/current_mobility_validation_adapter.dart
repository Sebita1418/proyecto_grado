import '../mobility_context.dart';
import '../mobility_recommendation.dart';
import '../route_option.dart';
import '../transport_mode.dart';
import '../../models/incident_report_draft.dart';
import 'mobility_validation.dart';

/// Projects existing observations, without ranking, geometry analysis or IO.
class CurrentMobilityValidationAdapter {
  const CurrentMobilityValidationAdapter();
  MobilityValidationInput build({
    required MobilityContext context,
    required List<RouteOption> options,
    required MobilityRecommendation? recommendation,
    required String? markedSuggestedId,
    required String? selectedId,
    required bool manuallySelected,
  }) => MobilityValidationInput(
    alternatives: [
      for (var i = 0; i < options.length; i++)
        ValidationAlternative(
          id: options[i].id,
          providerOrder: i,
          eligible:
              options[i].mode == TransportMode.driving &&
              context.allowedModes.contains(options[i].mode),
          seconds: options[i].route.durationSeconds,
          meters: options[i].route.distanceMeters,
          source: options[i].source,
          reports:
              context.incidentAnalyses[options[i].id]?.routeId == options[i].id
              ? context.incidentAnalyses[options[i].id]!.total
              : null,
          closures:
              context.incidentAnalyses[options[i].id]?.routeId == options[i].id
              ? context.incidentAnalyses[options[i].id]!.categories[IncidentType
                        .roadClosed] ??
                    0
              : null,
        ),
    ],
    suggestedId: recommendation?.recommended.id,
    markedSuggestedId: markedSuggestedId,
    selectedId: selectedId,
    manuallySelected: manuallySelected,
    suggestedSeconds: recommendation?.recommended.route.durationSeconds,
    suggestedMeters: recommendation?.recommended.route.distanceMeters,
    evaluatedAt: recommendation?.evaluatedAt,
    recommendationIds: recommendation == null
        ? []
        : [
            recommendation.recommended.id,
            ...recommendation.alternatives.map((o) => o.id),
          ],
    reasons:
        recommendation?.reasons.map(
          (r) => ValidationReason(r.factor.name, r.explanation),
        ) ??
        [],
  );
}
