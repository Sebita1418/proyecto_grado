import 'package:latlong2/latlong.dart';

import 'navigation_progress.dart';

class RouteProximityResult {
  const RouteProximityResult(this.distanceMeters, this.isNearRoute);
  final double? distanceMeters;
  final bool isNearRoute;
}

/// Spatial proximity only; it says nothing about delays or travel impact.
class RouteProximity {
  RouteProximity(List<LatLng> points, {this.thresholdMeters = 100})
    : _geometry = points.isEmpty || !points.every(_valid)
          ? null
          : NavigationProgress(points) {
    if (!thresholdMeters.isFinite || thresholdMeters < 0) {
      throw ArgumentError.value(thresholdMeters, 'thresholdMeters');
    }
  }

  final double thresholdMeters;
  final NavigationProgress? _geometry;
  static bool _valid(LatLng p) =>
      p.latitude.isFinite &&
      p.longitude.isFinite &&
      p.latitude.abs() <= 90 &&
      p.longitude.abs() <= 180;

  RouteProximityResult classify(LatLng point) {
    if (_geometry == null || !_valid(point))
      return const RouteProximityResult(null, false);
    final distance = _geometry
        .project(point, includeGeometry: false)
        .distanceToRoute;
    return RouteProximityResult(distance, distance <= thresholdMeters);
  }
}
