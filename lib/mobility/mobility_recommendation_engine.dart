import 'mobility_context.dart';
import 'mobility_recommendation.dart';
import 'route_option.dart';

/// Contract only. No recommendation strategy is implemented yet.
abstract interface class MobilityRecommendationEngine {
  Future<MobilityRecommendation> recommend(
    MobilityContext context,
    List<RouteOption> options,
  );
}
