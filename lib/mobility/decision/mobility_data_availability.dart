enum MobilityDataKind {
  location,
  routing,
  durationAndDistance,
  roadConditions,
  temporal,
  transport,
}

/// Availability of usable evidence, never the value of a measured condition.
enum MobilityDataStatus { unknown, unavailable, partial, available }

/// Evidence for one mode and departure context. Missing entries remain unknown.
/// Available road conditions may contain reports; unavailable never means zero.
final class MobilityDataAvailability {
  MobilityDataAvailability({
    Map<MobilityDataKind, MobilityDataStatus> statuses = const {},
  }) : statuses = Map.unmodifiable(statuses);

  final Map<MobilityDataKind, MobilityDataStatus> statuses;

  MobilityDataStatus statusOf(MobilityDataKind kind) =>
      statuses[kind] ?? MobilityDataStatus.unknown;

  bool hasAll(Iterable<MobilityDataKind> requiredData) => requiredData.every(
    (kind) => statusOf(kind) == MobilityDataStatus.available,
  );
}
