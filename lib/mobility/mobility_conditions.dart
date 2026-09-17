enum CongestionLevel { low, moderate, high }

/// Null values mean that a condition has not been measured.
class MobilityConditions {
  MobilityConditions({
    this.congestion,
    int? relevantIncidentCount,
    double? estimatedDelaySeconds,
    this.evaluatedAt,
  }) : relevantIncidentCount = relevantIncidentCount,
       estimatedDelaySeconds = estimatedDelaySeconds {
    if (relevantIncidentCount != null && relevantIncidentCount < 0) {
      throw ArgumentError.value(relevantIncidentCount, 'relevantIncidentCount');
    }
    if (estimatedDelaySeconds != null &&
        (!estimatedDelaySeconds.isFinite || estimatedDelaySeconds < 0)) {
      throw ArgumentError.value(estimatedDelaySeconds, 'estimatedDelaySeconds');
    }
  }

  final CongestionLevel? congestion;
  final int? relevantIncidentCount;
  final double? estimatedDelaySeconds;
  final DateTime? evaluatedAt;

  bool get isUnknown =>
      congestion == null &&
      relevantIncidentCount == null &&
      estimatedDelaySeconds == null;
}
