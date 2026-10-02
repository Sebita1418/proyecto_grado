import '../transport_mode.dart';
import 'mobility_data_availability.dart';

enum MobilityOptionStatus {
  evaluable,
  insufficientData,
  temporarilyUnavailable,
  unsupported,
}

/// Declared capability, not an evaluator or a registry of enabled product modes.
final class MobilityOptionAvailability {
  MobilityOptionAvailability({
    required this.mode,
    required this.status,
    required this.data,
    Set<MobilityDataKind> additionalRequiredData = const {},
  }) : requiredData = Set.unmodifiable({
         MobilityDataKind.location,
         MobilityDataKind.routing,
         MobilityDataKind.durationAndDistance,
         ...additionalRequiredData,
       }) {
    if (canEvaluate && !hasSufficientData) {
      throw ArgumentError('An evaluable option requires usable route evidence');
    }
    if (status == MobilityOptionStatus.insufficientData && hasSufficientData) {
      throw ArgumentError(
        'Insufficient data requires missing or partial evidence',
      );
    }
  }

  final TransportMode mode;
  final MobilityOptionStatus status;
  final MobilityDataAvailability data;
  final Set<MobilityDataKind> requiredData;

  bool get isSupported => status != MobilityOptionStatus.unsupported;
  bool get canEvaluate => status == MobilityOptionStatus.evaluable;
  bool get hasSufficientData => data.hasAll(requiredData);
}
