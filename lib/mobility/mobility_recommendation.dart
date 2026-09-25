import 'route_option.dart';

/// Identifies the evidence category without assigning an invented score.
enum RecommendationFactor { distance, duration, conditions, preference, other }

class RecommendationReason {
  RecommendationReason({required this.factor, required String explanation})
    : explanation = explanation.trim() {
    if (this.explanation.isEmpty) {
      throw ArgumentError.value(explanation, 'explanation');
    }
  }

  final RecommendationFactor factor;
  final String explanation;
}

/// An engine's decision; alternatives exclude [recommended].
class MobilityRecommendation {
  MobilityRecommendation({
    required this.recommended,
    required List<RouteOption> alternatives,
    required List<RecommendationReason> reasons,
    required this.evaluatedAt,
  }) : alternatives = List.unmodifiable(alternatives),
       reasons = List.unmodifiable(reasons) {
    if (this.reasons.isEmpty) throw ArgumentError.value(reasons, 'reasons');
    final ids = <String>{recommended.id};
    for (final option in this.alternatives) {
      if (!ids.add(option.id)) {
        throw ArgumentError.value(alternatives, 'alternatives', 'Duplicate id');
      }
    }
  }

  final RouteOption recommended;
  final List<RouteOption> alternatives;
  final List<RecommendationReason> reasons;
  final DateTime evaluatedAt;
}
