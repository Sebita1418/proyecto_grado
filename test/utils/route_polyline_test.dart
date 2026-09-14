import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:transporte_inteligente/utils/route_polyline.dart';

void main() {
  group('RoutePolyline', () {
    test('crea una polyline cuando hay al menos dos puntos', () {
      const points = <LatLng>[
        LatLng(7.1193, -73.1227),
        LatLng(7.1254, -73.1198),
      ];

      final polylines = RoutePolyline.build(points: points);

      expect(polylines, hasLength(1));

      final polyline = polylines.first;

      expect(polyline.polylineId, RoutePolyline.routePolylineId);
      expect(polyline.points, points);
      expect(polyline.width, 5);
    });

    test('devuelve conjunto vacío cuando no hay puntos', () {
      final polylines = RoutePolyline.build(points: const <LatLng>[]);

      expect(polylines, isEmpty);
    });

    test('devuelve conjunto vacío cuando hay solo un punto', () {
      final polylines = RoutePolyline.build(
        points: const <LatLng>[LatLng(7.1193, -73.1227)],
      );

      expect(polylines, isEmpty);
    });
  });
}
