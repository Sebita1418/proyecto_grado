import '../mobility_recommendation.dart';
import '../transport_mode.dart';
import 'mobility_decision_context.dart';
import 'mobility_decision_result.dart';
import 'mobility_option_availability.dart';

/// Wraps an existing vehicle decision without routing, ranking or fetching data.
class MobilityDecisionCoordinator {
  const MobilityDecisionCoordinator();

  MobilityDecisionResult decide(
    MobilityDecisionContext context, {
    MobilityRecommendation? vehicleRecommendation,
  }) {
    final driving = context.options
        .where((o) => o.mode == TransportMode.driving)
        .firstOrNull;
    if (context.departureTime.isNow &&
        driving?.canEvaluate == true &&
        vehicleRecommendation != null &&
        [
          vehicleRecommendation.recommended,
          ...vehicleRecommendation.alternatives,
        ].every((o) => o.mode == TransportMode.driving)) {
      return MobilityDecisionResult.recommended(
        context: context,
        recommendation: vehicleRecommendation,
        evaluatedModes: const [TransportMode.driving],
      );
    }
    return MobilityDecisionResult.withoutRecommendation(
      context: context,
      reason:
          context.departureTime.isScheduled ||
              context.options.any(
                (o) =>
                    o.canEvaluate ||
                    o.status == MobilityOptionStatus.insufficientData,
              )
          ? NoMobilityRecommendationReason.insufficientEvidence
          : NoMobilityRecommendationReason.noEvaluableOptions,
    );
  }
}
