import 'mobility_context.dart';
import 'mobility_recommendation.dart';
import 'mobility_recommendation_engine.dart';
import 'route_option.dart';
import 'transport_mode.dart';
import 'vehicle_recommendation_policy.dart';

/// No decision exists when the supplied modes/options have no driving candidate.
class NoEligibleVehicleRouteException implements Exception {
  const NoEligibleVehicleRouteException();
}

/// Provisional, bounded incident exposure rule; no conversion to travel time.
class VehicleRecommendationEngine implements MobilityRecommendationEngine {
  VehicleRecommendationEngine({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  static const comparableDurationRatio =
      VehicleRecommendationPolicy.comparableDurationRatio;
  static const comparableDistanceRatio =
      VehicleRecommendationPolicy.comparableDistanceRatio;

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
      if (option.route.origin != context.origin ||
          option.route.destination != context.destination) {
        throw ArgumentError('Route endpoints do not match the requested trip');
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
    // Only compare exposure when every candidate has a matching snapshot.
    if (eligible.every(
      (o) => context.incidentAnalyses[o.id]?.routeId == o.id,
    )) {
      final baseline = selected;
      var comparable = eligible
          .where(
            (o) =>
                o.route.durationSeconds <=
                    baseline.route.durationSeconds * comparableDurationRatio &&
                o.route.distanceMeters <=
                    baseline.route.distanceMeters * comparableDistanceRatio,
          )
          .toList();
      final withoutClosures = comparable
          .where((o) => !context.incidentAnalyses[o.id]!.hasRoadClosure)
          .toList();
      final avoidedClosure =
          withoutClosures.isNotEmpty &&
          withoutClosures.length != comparable.length;
      if (withoutClosures.isNotEmpty) comparable = withoutClosures;
      final minimum = comparable
          .map((o) => context.incidentAnalyses[o.id]!.total)
          .reduce((a, b) => a < b ? a : b);
      final finalists = comparable
          .where((o) => context.incidentAnalyses[o.id]!.total == minimum)
          .toList();
      final decision = await recommend(
        MobilityContext(
          origin: context.origin,
          destination: context.destination,
          allowedModes: context.allowedModes,
          requestedAt: context.requestedAt,
        ),
        finalists,
      );
      final chosen = decision.recommended;
      return MobilityRecommendation(
        recommended: chosen,
        alternatives: [
          for (final o in eligible)
            if (o.id != chosen.id) o,
        ],
        evaluatedAt: _clock(),
        reasons: [
          RecommendationReason(
            factor: RecommendationFactor.conditions,
            explanation: minimum == 0
                ? 'Ruta sugerida: sin reportes viales activos próximos en los datos disponibles.'
                : 'Ruta sugerida: menor exposición a reportes activos entre alternativas comparables con igual condición de cierres.',
          ),
          if (avoidedClosure)
            RecommendationReason(
              factor: RecommendationFactor.conditions,
              explanation: 'Se prioriza una alternativa sin cierres viales reportados próximos dentro del grupo comparable.',
            ),
          RecommendationReason(
            factor: RecommendationFactor.other,
            explanation: 'Regla provisional: grupo comparable hasta 25 % más de duración y 50 % más de distancia que la ruta más rápida. La proximidad no confirma bloqueo ni sentido de circulación.',
          ),
          for (final reason in decision.reasons)
            RecommendationReason(
              factor: reason.factor,
              explanation:
                  '${reason.explanation.replaceAll('entre las alternativas vehiculares elegibles recibidas', 'entre las alternativas finalistas con igual exposición').replaceAll('Única alternativa vehicular elegible recibida para este cálculo.', 'Única alternativa finalista tras comparar proximidad y límites de duración/distancia.')} Tiempos y distancias del proveedor sin ajustes.',
            ),
        ],
      );
    }
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
