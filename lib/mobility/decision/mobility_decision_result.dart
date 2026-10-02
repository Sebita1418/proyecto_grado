import '../mobility_recommendation.dart';
import '../transport_mode.dart';
import 'mobility_decision_context.dart';
import 'mobility_option_availability.dart';

enum NoMobilityRecommendationReason {
  insufficientEvidence,
  noEvaluableOptions,
  inconclusiveEvaluation,
}

/// A completed caller-supplied evaluation; this type never ranks modes or routes.
/// Recommendation scope is limited to [evaluatedModes], not all domain modes.
final class MobilityDecisionResult {
  MobilityDecisionResult.recommended({
    required MobilityDecisionContext context,
    required MobilityRecommendation recommendation,
    required Iterable<TransportMode> evaluatedModes,
  }) : this._(
         context: context,
         recommendation: recommendation,
         evaluatedModes: evaluatedModes,
       );

  MobilityDecisionResult.withoutRecommendation({
    required MobilityDecisionContext context,
    required NoMobilityRecommendationReason reason,
    Iterable<TransportMode> evaluatedModes = const [],
  }) : this._(
         context: context,
         noRecommendationReason: reason,
         evaluatedModes: evaluatedModes,
       );

  MobilityDecisionResult._({
    required this.context,
    required Iterable<TransportMode> evaluatedModes,
    this.recommendation,
    this.noRecommendationReason,
  }) : evaluatedModes = List.unmodifiable(evaluatedModes) {
    final modes = <TransportMode>{};
    for (final mode in this.evaluatedModes) {
      if (!modes.add(mode) ||
          !context.options.any((o) => o.mode == mode && o.canEvaluate)) {
        throw ArgumentError('Evaluated modes must be unique and evaluable');
      }
    }
    if (noRecommendationReason ==
            NoMobilityRecommendationReason.noEvaluableOptions &&
        context.options.any((o) => o.canEvaluate)) {
      throw ArgumentError('The context contains evaluable options');
    }
    if (noRecommendationReason ==
            NoMobilityRecommendationReason.inconclusiveEvaluation &&
        modes.isEmpty) {
      throw ArgumentError(
        'An inconclusive evaluation requires evaluated modes',
      );
    }
    final decision = recommendation;
    if (decision != null) {
      for (final option in [decision.recommended, ...decision.alternatives]) {
        if (!modes.contains(option.mode)) {
          throw ArgumentError(
            'Recommended routes must belong to evaluated modes',
          );
        }
        if (option.route.origin != context.mobilityContext.origin ||
            option.route.destination != context.mobilityContext.destination) {
          throw ArgumentError('Recommended routes must match the trip');
        }
      }
    }
  }

  final MobilityDecisionContext context;
  final MobilityRecommendation? recommendation;
  final NoMobilityRecommendationReason? noRecommendationReason;
  final List<TransportMode> evaluatedModes;

  bool get hasRecommendation => recommendation != null;

  List<MobilityOptionAvailability> get evaluatedOptions => List.unmodifiable(
    context.options.where((o) => evaluatedModes.contains(o.mode)),
  );

  List<MobilityOptionAvailability> get nonEvaluableOptions =>
      List.unmodifiable(context.options.where((o) => !o.canEvaluate));

  /// Evaluable does not mean actually evaluated by the caller.
  List<MobilityOptionAvailability> get unevaluatedOptions => List.unmodifiable(
    context.options.where(
      (o) => o.canEvaluate && !evaluatedModes.contains(o.mode),
    ),
  );
}
