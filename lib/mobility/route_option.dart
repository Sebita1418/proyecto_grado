import 'package:latlong2/latlong.dart';

import '../models/route_result.dart';
import 'mobility_conditions.dart';
import 'transport_mode.dart';

/// Domain metadata around an existing provider-neutral route result.
class RouteOption {
  RouteOption.fromRouteResult({
    required String id,
    required this.mode,
    required RouteResult route,
    MobilityConditions? conditions,
    String? source,
  }) : id = id.trim(),
       source = source?.trim(),
       conditions = conditions ?? MobilityConditions(),
       route = _validatedCopy(route) {
    if (this.id.isEmpty) throw ArgumentError.value(id, 'id');
    if (this.source != null && this.source!.isEmpty) {
      throw ArgumentError.value(source, 'source');
    }
  }

  final String id;
  final TransportMode mode;
  final RouteResult route;
  final MobilityConditions conditions;
  final String? source;

  static RouteResult _validatedCopy(RouteResult value) {
    if (!_validPoint(value.origin) || !_validPoint(value.destination)) {
      throw ArgumentError.value(value, 'route', 'Invalid endpoint');
    }
    if (value.points.length < 2 || value.points.any((p) => !_validPoint(p))) {
      throw ArgumentError.value(value, 'route', 'Invalid geometry');
    }
    if (!value.distanceMeters.isFinite || value.distanceMeters < 0) {
      throw ArgumentError.value(value.distanceMeters, 'distanceMeters');
    }
    if (!value.durationSeconds.isFinite || value.durationSeconds < 0) {
      throw ArgumentError.value(value.durationSeconds, 'durationSeconds');
    }
    return RouteResult(
      origin: value.origin,
      destination: value.destination,
      points: List<LatLng>.unmodifiable(value.points),
      distanceMeters: value.distanceMeters,
      durationSeconds: value.durationSeconds,
    );
  }

  static bool _validPoint(LatLng point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude.abs() <= 90 &&
      point.longitude.abs() <= 180;
}
