enum DepartureTimeKind { now, scheduled }

/// An explicit departure instant, not a forecast or a preferred travel time.
final class DepartureTimeContext {
  const DepartureTimeContext.now(this.at) : kind = DepartureTimeKind.now;

  const DepartureTimeContext.scheduled(this.at)
    : kind = DepartureTimeKind.scheduled;

  final DepartureTimeKind kind;
  final DateTime at;

  bool get isNow => kind == DepartureTimeKind.now;
  bool get isScheduled => kind == DepartureTimeKind.scheduled;
}
