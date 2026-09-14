import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utilidad para construir la representación visual de una ruta
/// mediante una Polyline de Google Maps.
class RoutePolyline {
  const RoutePolyline._();

  static const PolylineId routePolylineId = PolylineId('route_polyline');

  static Set<Polyline> build({required List<LatLng> points}) {
    if (points.length < 2) {
      return const <Polyline>{};
    }

    return <Polyline>{
      Polyline(
        polylineId: routePolylineId,
        points: List<LatLng>.unmodifiable(points),
        width: 5,
      ),
    };
  }
}
