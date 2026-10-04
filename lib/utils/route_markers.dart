import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utilidad para construir los marcadores visuales
/// de origen y destino de una ruta.
class RouteMarkers {
  const RouteMarkers._();

  static const MarkerId originMarkerId = MarkerId('route_origin');
  static const MarkerId destinationMarkerId = MarkerId('route_destination');

  static Set<Marker> build({
    required LatLng origin,
    required LatLng destination,
  }) {
    return <Marker>{
      Marker(
        markerId: originMarkerId,
        position: origin,
        infoWindow: const InfoWindow(title: 'Origen'),
      ),
      Marker(
        markerId: destinationMarkerId,
        position: destination,
        infoWindow: const InfoWindow(title: 'Destino'),
      ),
    };
  }
}
