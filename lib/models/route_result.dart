import 'package:latlong2/latlong.dart';

import '../navigation/navigation_instruction.dart';

/// A vehicle route with provider-independent geometry and measurements.
class RouteResult {
  const RouteResult({
    required this.origin,
    required this.destination,
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.instructions = const [],
  });

  final LatLng origin;
  final LatLng destination;
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<NavigationInstruction> instructions;
}
