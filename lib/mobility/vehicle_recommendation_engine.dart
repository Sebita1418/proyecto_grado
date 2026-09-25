import 'mobility_context.dart';
import 'mobility_recommendation.dart';
import 'mobility_recommendation_engine.dart';
import 'route_option.dart';
import 'transport_mode.dart';

/// No decision exists when the supplied modes/options have no driving candidate.
class NoEligibleVehicleRouteException implements Exception {
  const NoEligibleVehicleRouteException();
}

/// Provisional technical rule: duration, then distance, then provider order.
/// Conditions are deliberately not scored: no productive source supplies them.
class VehicleRecommendationEngine implements MobilityRecommendationEngine {
  VehicleRecommendationEngine({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  Future<MobilityRecommendation> recommend(
    MobilityContext context,
    List<RouteOption> options,
  ) async {
    // Revalidate at the engine boundary, including externally implemented models.
    MobilityContext(
      origin: context.origin,
      destination: context.destination,
      allowedModes: context.allowedModes,
      requestedAt: context.requestedAt,
    );
    final ids = <String>{};
    for (final option in options) {
      RouteOption.fromRouteResult(
        id: option.id,
        mode: option.mode,
        route: option.route,
        source: option.source,
      );
      if (!ids.add(option.id.trim())) {
        throw ArgumentError('Duplicate route option id');
      }
    }
    final eligible = options
        .where(
          (option) =>
              option.mode == TransportMode.driving &&
              context.allowedModes.contains(option.mode),
        )
        .toList(growable: false);
    if (eligible.isEmpty) throw const NoEligibleVehicleRouteException();

    var selected = eligible.first;
    for (final candidate in eligible.skip(1)) {
      final route = candidate.route;
      final best = selected.route;
      if (route.durationSeconds < best.durationSeconds ||
          (route.durationSeconds == best.durationSeconds &&
              route.distanceMeters < best.distanceMeters)) {
        selected = candidate;
      }
    }
    final reasons = <RecommendationReason>[];
    if (eligible.length == 1) {
      reasons.add(
        RecommendationReason(
          factor: RecommendationFactor.other,
          explanation: 'Única alternativa vehicular elegible recibida para este cálculo.',
        ),
      );
    } else {
      final tiedDuration = eligible
          .where(
            (option) =>
                option.route.durationSeconds == selected.route.durationSeconds,
          )
          .toList(growable: false);
      reasons.add(
        RecommendationReason(
          factor: RecommendationFactor.duration,
          explanation: tiedDuration.length == 1
              ? 'Menor duración estimada entre las alternativas vehiculares elegibles recibidas.'
              : 'Comparte la menor duración estimada entre las alternativas vehiculares elegibles recibidas.',
        ),
      );
      if (tiedDuration.any(
        (option) => option.route.distanceMeters > selected.route.distanceMeters,
      )) {
        reasons.add(
          RecommendationReason(
            factor: RecommendationFactor.distance,
            explanation: 'Menor distancia como desempate entre las alternativas con igual duración estimada.',
          ),
        );
      }
      if (tiedDuration
              .where(
                (option) =>
                    option.route.distanceMeters ==
                    selected.route.distanceMeters,
              )
              .length >
          1) {
        reasons.add(
          RecommendationReason(
            factor: RecommendationFactor.other,
            explanation: 'Ante igual duración y distancia, se conserva el orden del proveedor.',
          ),
        );
      }
    }
    return MobilityRecommendation(
      recommended: selected,
      alternatives: [
        for (final option in eligible)
          if (option.id != selected.id) option,
      ],
      reasons: reasons,
      evaluatedAt: _clock(),
    );
  }
}
