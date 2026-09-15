import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:transporte_inteligente/utils/route_markers.dart';

void main() {
  group('RouteMarkers', () {
    test('crea exactamente dos marcadores', () {
      const origin = LatLng(7.1193, -73.1227);
      const destination = LatLng(7.1254, -73.1198);

      final markers = RouteMarkers.build(
        origin: origin,
        destination: destination,
      );

      expect(markers, hasLength(2));
    });

    test('conserva las coordenadas de origen y destino', () {
      const origin = LatLng(7.1193, -73.1227);
      const destination = LatLng(7.1254, -73.1198);

      final markers = RouteMarkers.build(
        origin: origin,
        destination: destination,
      );

      final originMarker = markers.firstWhere(
        (marker) => marker.markerId == RouteMarkers.originMarkerId,
      );

      final destinationMarker = markers.firstWhere(
        (marker) => marker.markerId == RouteMarkers.destinationMarkerId,
      );

      expect(originMarker.position, origin);
      expect(destinationMarker.position, destination);
    });

    test('usa identificadores diferentes para origen y destino', () {
      expect(
        RouteMarkers.originMarkerId,
        isNot(RouteMarkers.destinationMarkerId),
      );
    });
  });
}
