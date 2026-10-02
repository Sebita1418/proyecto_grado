import '../mobility_context.dart';
import '../transport_mode.dart';
import 'departure_time_context.dart';
import 'mobility_data_availability.dart';
import 'mobility_option_availability.dart';

/// Composes the existing trip and allowed-mode preferences without fetching data.
final class MobilityDecisionContext {
  MobilityDecisionContext({
    required this.mobilityContext,
    required this.departureTime,
    required Iterable<MobilityOptionAvailability> options,
  }) : options = List.unmodifiable(options) {
    final modes = <TransportMode>{};
    for (final option in this.options) {
      if (!modes.add(option.mode)) {
        throw ArgumentError('Duplicate considered mode');
      }
      if (!mobilityContext.allowedModes.contains(option.mode)) {
        throw ArgumentError('Considered mode is not allowed by the trip');
      }
      if (departureTime.isScheduled &&
          option.canEvaluate &&
          !option.data.hasAll({MobilityDataKind.temporal})) {
        throw ArgumentError('Scheduled evaluation requires temporal evidence');
      }
    }
  }

  final MobilityContext mobilityContext;
  final DepartureTimeContext departureTime;
  final List<MobilityOptionAvailability> options;

  Set<TransportMode> get consideredModes =>
      Set.unmodifiable(options.map((option) => option.mode));

  Map<TransportMode, MobilityDataAvailability> get dataAvailability =>
      Map.unmodifiable({
        for (final option in options) option.mode: option.data,
      });
}
