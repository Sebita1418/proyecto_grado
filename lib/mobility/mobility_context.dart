import 'package:latlong2/latlong.dart';

import 'mobility_conditions.dart';
import 'transport_mode.dart';

/// Information available when alternatives are requested.
class MobilityContext {
  MobilityContext({
    required this.origin,
    required this.destination,
    required Set<TransportMode> allowedModes,
    required this.requestedAt,
    MobilityConditions? generalConditions,
  }) : allowedModes = Set.unmodifiable(allowedModes),
       generalConditions = generalConditions ?? MobilityConditions() {
    if (!_validPoint(origin) || !_validPoint(destination)) {
      throw ArgumentError('Invalid origin or destination');
    }
    if (allowedModes.isEmpty) {
      throw ArgumentError.value(allowedModes, 'allowedModes');
    }
  }

  final LatLng origin;
  final LatLng destination;
  final Set<TransportMode> allowedModes;
  final DateTime requestedAt;
  final MobilityConditions generalConditions;

  static bool _validPoint(LatLng point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude.abs() <= 90 &&
      point.longitude.abs() <= 180;
}
