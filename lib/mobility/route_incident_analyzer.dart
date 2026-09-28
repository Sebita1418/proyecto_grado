import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/road_incident_report.dart';
import 'route_incident_analysis.dart';

/// Local equirectangular projection around the incident, in metres.
/// Suitable for urban corridors, not lane/direction matching.
class RouteIncidentAnalyzer {
  const RouteIncidentAnalyzer();
  static const proximityMeters = 125.0;
  static const _earthRadius = 6371008.8;

  RouteIncidentAnalysis analyze({
    required String routeId,
    required List<LatLng> geometry,
    required Iterable<RoadIncidentReport> reports,
    required DateTime now,
  }) {
    if (geometry.length < 2 ||
        !geometry.every(RoadIncidentReport.validCoordinates)) {
      throw ArgumentError('Invalid route geometry');
    }
    final seen = <String>{};
    final matches = <RouteIncidentProximity>[];
    for (final report in reports) {
      if (!report.isActiveAt(now) ||
          report.id.trim().isEmpty ||
          !report.expiresAt.isAfter(report.createdAt) ||
          !RoadIncidentReport.validCoordinates(report.coordinates) ||
          !seen.add(report.id)) {
        continue;
      }
      var closest = double.infinity;
      for (var i = 1; i < geometry.length; i++) {
        closest = math.min(
          closest,
          _segmentDistance(report.coordinates, geometry[i - 1], geometry[i]),
        );
      }
      if (closest <= proximityMeters) {
        matches.add(RouteIncidentProximity(report, closest));
      }
    }
    matches.sort((a, b) => a.report.id.compareTo(b.report.id));
    return RouteIncidentAnalysis(
      routeId: routeId,
      evaluatedAt: now,
      incidents: matches,
    );
  }

  double _segmentDistance(LatLng point, LatLng a, LatLng b) {
    const radians = math.pi / 180;
    final scale = _earthRadius * radians;
    final longitudeScale = scale * math.cos(point.latitude * radians);
    double longitudeDelta(double longitude) =>
        (longitude - point.longitude + 540) % 360 - 180;
    final ax = longitudeDelta(a.longitude) * longitudeScale;
    final ay = (a.latitude - point.latitude) * scale;
    final bx = longitudeDelta(b.longitude) * longitudeScale;
    final by = (b.latitude - point.latitude) * scale;
    final dx = bx - ax, dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;
    final t = lengthSquared == 0
        ? 0.0
        : (-(ax * dx + ay * dy) / lengthSquared).clamp(0.0, 1.0);
    return math.sqrt(math.pow(ax + t * dx, 2) + math.pow(ay + t * dy, 2));
  }
}
