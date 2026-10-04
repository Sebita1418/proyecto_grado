import '../models/route_result.dart';

/// Comparison metadata only; indices retain the provider's original order.
class RouteAlternativesAnalysis {
  RouteAlternativesAnalysis._({
    required this.fastestIndex,
    required this.shortestIndex,
    required List<({double extraSeconds, double extraMeters})> differences,
  }) : differences = List.unmodifiable(differences);

  final int? fastestIndex;
  final int? shortestIndex;
  final List<({double extraSeconds, double extraMeters})> differences;
}

/// Pure metric comparison, independent of UI, network and user preferences.
class RouteAlternativesAnalysisService {
  const RouteAlternativesAnalysisService();

  RouteAlternativesAnalysis analyze(List<RouteResult> alternatives) {
    if (alternatives.isEmpty) {
      return RouteAlternativesAnalysis._(
        fastestIndex: null,
        shortestIndex: null,
        differences: [],
      );
    }
    var fastest = 0;
    var shortest = 0;
    for (var index = 0; index < alternatives.length; index++) {
      final route = alternatives[index];
      if (!route.durationSeconds.isFinite ||
          route.durationSeconds < 0 ||
          !route.distanceMeters.isFinite ||
          route.distanceMeters < 0) {
        throw ArgumentError.value(
          index,
          'alternatives',
          'Invalid route metrics',
        );
      }
      // Strict comparisons preserve the first provider candidate on exact ties.
      if (route.durationSeconds < alternatives[fastest].durationSeconds) {
        fastest = index;
      }
      if (route.distanceMeters < alternatives[shortest].distanceMeters) {
        shortest = index;
      }
    }
    return RouteAlternativesAnalysis._(
      fastestIndex: fastest,
      shortestIndex: shortest,
      differences: [
        for (final route in alternatives)
          (
            extraSeconds:
                route.durationSeconds - alternatives[fastest].durationSeconds,
            extraMeters:
                route.distanceMeters - alternatives[shortest].distanceMeters,
          ),
      ],
    );
  }
}
