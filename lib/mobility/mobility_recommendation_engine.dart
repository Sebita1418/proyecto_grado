import 'mobility_context.dart';
import 'mobility_recommendation.dart';
import 'route_option.dart';

/// Provider-neutral contract; VehicleRecommendationEngine is the driving policy.
abstract interface class MobilityRecommendationEngine {
  Future<MobilityRecommendation> recommend(
    MobilityContext context,
    List<RouteOption> options,
  );
}
