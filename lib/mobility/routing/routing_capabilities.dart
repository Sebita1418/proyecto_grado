import '../transport_mode.dart';

class RoutingCapabilities {
  RoutingCapabilities(Iterable<TransportMode> modes)
    : modes = Set.unmodifiable(modes);
  final Set<TransportMode> modes;
  bool supports(TransportMode mode) => modes.contains(mode);
}

enum ModeAvailability { available, unavailable, unknown, error }

enum RoutingFailure {
  unsupported,
  unavailable,
  networkError,
  timeout,
  noRoute,
  invalidResponse,
}

class ModeRouteSummary {
  const ModeRouteSummary({
    required this.mode,
    required this.availability,
    required this.reason,
    this.durationSeconds,
    this.distanceMeters,
    this.provider,
    this.alternativeCount,
    this.failure,
  });
  final TransportMode mode;
  final ModeAvailability availability;
  final String reason;
  final double? durationSeconds, distanceMeters;
  final String? provider;
  final int? alternativeCount;
  final RoutingFailure? failure;
}

/// Descriptive per-mode evidence for one unchanged origin/destination pair.
class MultimodalMobilitySnapshot {
  MultimodalMobilitySnapshot(Iterable<ModeRouteSummary> summaries)
    : summaries = Map.unmodifiable({for (final s in summaries) s.mode: s});
  final Map<TransportMode, ModeRouteSummary> summaries;
}
