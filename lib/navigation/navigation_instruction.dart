import 'package:latlong2/latlong.dart';

enum ManeuverType {
  depart,
  arrive,
  turn,
  continueRoad,
  merge,
  fork,
  roundabout,
  rotary,
  newName,
  endOfRoad,
  onRamp,
  offRamp,
  exitRoundabout,
  unknown,
}

enum ManeuverDirection {
  left,
  right,
  slightLeft,
  slightRight,
  sharpLeft,
  sharpRight,
  straight,
  uturn,
  unknown,
}

/// Datos de navegación independientes del JSON y del proveedor.
class NavigationInstruction {
  const NavigationInstruction({
    required this.type,
    required this.direction,
    required this.position,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.distanceFromStart,
    this.streetName = '',
    this.exit,
  });
  final ManeuverType type;
  final ManeuverDirection direction;
  final LatLng position;
  final double distanceMeters, durationSeconds, distanceFromStart;
  final String streetName;
  final int? exit;
}
