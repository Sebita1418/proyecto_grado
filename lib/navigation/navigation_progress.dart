import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Local projection onto the closest segment, weighted by segment length.
/// Repeated vertices are supported; ties prefer the earliest segment.
class NavigationProgress {
  NavigationProgress(List<LatLng> geometry)
    : points = List.unmodifiable(geometry) {
    for (var i = 1; i < points.length; i++) {
      lengths.add(
        const Distance().as(LengthUnit.Meter, points[i - 1], points[i]),
      );
    }
    total = lengths.fold(0, (sum, length) => sum + length);
  }

  final List<LatLng> points;
  final List<double> lengths = [];
  late final double total;

  RouteProjection project(LatLng position) {
    var nearest = double.infinity;
    var along = 0.0;
    var prefix = 0.0;
    var index = 0;
    var snapped = points.first;
    final scale = math.cos(position.latitude * math.pi / 180);
    for (var i = 0; i < lengths.length; i++) {
      final a = points[i];
      final b = points[i + 1];
      final dx = (b.longitude - a.longitude) * scale;
      final dy = b.latitude - a.latitude;
      final denominator = dx * dx + dy * dy;
      final t = denominator == 0
          ? 0.0
          : (((position.longitude - a.longitude) * scale * dx +
                        (position.latitude - a.latitude) * dy) /
                    denominator)
                .clamp(0.0, 1.0);
      final point = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      final distance = const Distance().as(LengthUnit.Meter, position, point);
      if (distance < nearest) {
        nearest = distance;
        along = prefix + lengths[i] * t;
        index = i;
        snapped = point;
      }
      prefix += lengths[i];
    }
    return RouteProjection(
      progress: total == 0 ? 0 : (along / total).clamp(0.0, 1.0),
      distanceToRoute: nearest,
      traveled: [...points.take(index + 1), snapped],
      remaining: [snapped, ...points.skip(index + 1)],
    );
  }
}

class RouteProjection {
  const RouteProjection({
    required this.progress,
    required this.distanceToRoute,
    required this.traveled,
    required this.remaining,
  });
  final double progress, distanceToRoute;
  final List<LatLng> traveled, remaining;
}
