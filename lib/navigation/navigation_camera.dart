import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

/// 2D camera policy. Heading is GNSS course, never device compass orientation.
class NavigationCamera {
  NavigationCamera({this.zoom = 16});
  double zoom;
  LatLng? position;
  double rotation = 0;
  void reset() {
    position = null;
    rotation = 0;
  }

  bool accept(LocationResult fix) {
    final p = fix.coordinates;
    final accuracy = fix.accuracyMeters;
    if (p == null ||
        !p.latitude.isFinite ||
        !p.longitude.isFinite ||
        p.latitude.abs() > 90 ||
        p.longitude.abs() > 180 ||
        (accuracy != null &&
            (!accuracy.isFinite || accuracy < 0 || accuracy > 50))) {
      return false;
    }
    final stopped =
        fix.speedMetersPerSecond != null &&
        fix.speedMetersPerSecond!.isFinite &&
        fix.speedMetersPerSecond! < 1;
    if (!stopped ||
        position == null ||
        const Distance()(position!, p) > (accuracy ?? 5).clamp(5, 25)) {
      position = p;
    }
    final speed = fix.speedMetersPerSecond;
    final heading = fix.headingDegrees;
    final headingAccuracy = fix.headingAccuracyDegrees;
    if (speed != null &&
        speed.isFinite &&
        speed >= 2 &&
        accuracy != null &&
        accuracy <= 25 &&
        heading != null &&
        heading.isFinite &&
        heading >= 0 &&
        heading < 360 &&
        headingAccuracy != null &&
        headingAccuracy.isFinite &&
        headingAccuracy >= 0 &&
        headingAccuracy <= 25) {
      rotation = -heading;
    }
    return true;
  }

  static double angularDelta(double from, double to) =>
      (to - from + 180) % 360 - 180;
}
