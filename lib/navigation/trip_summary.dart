import '../mobility/mobility_recommendation.dart';
import '../models/route_result.dart';

/// The planning decision is retained even if navigation later reroutes.
class TripRouteContext {
  const TripRouteContext({
    this.originLabel = '',
    this.alternativeIndex,
    this.alternativeCount,
    this.recommendation,
    this.suggestedIndex,
    this.fastest = false,
    this.shortest = false,
  });

  final String originLabel;
  final int? alternativeIndex, alternativeCount, suggestedIndex;
  final MobilityRecommendation? recommendation;
  final bool fastest, shortest;
}

/// Immediate, in-memory summary. Route distance is never GPS distance traveled.
class TripSummary {
  const TripSummary({
    required this.selectedRoute,
    required this.context,
    required this.destination,
    required this.startedAt,
    required this.finishedAt,
    required this.reachedDestination,
    required this.hadPosition,
  });

  final RouteResult selectedRoute;
  final TripRouteContext context;
  final String destination;
  final DateTime startedAt, finishedAt;
  final bool reachedDestination, hadPosition;
  Duration get elapsed => finishedAt.difference(startedAt);
}
