import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/navigation/navigation_progress.dart';
import 'package:transporte_inteligente/navigation/route_proximity.dart';

void main() {
  const points = [LatLng(0, 0), LatLng(0, .02)];
  test('inicio, mitad y fin son cercanos; distancia espacial neutral', () {
    final service = RouteProximity(points, thresholdMeters: 100);
    for (final point in [points.first, const LatLng(0, .01), points.last]) {
      final result = service.classify(point);
      expect(result.isNearRoute, isTrue);
      expect(result.distanceMeters, closeTo(0, .1));
    }
    expect(service.classify(const LatLng(.0005, .01)).isNearRoute, isTrue);
    final outside = service.classify(const LatLng(.002, .01));
    expect(outside.isNearRoute, isFalse);
    expect(outside.distanceMeters, closeTo(222, 2));
    expect(service.classify(const LatLng(0, .03)).isNearRoute, isFalse);
  });
  test('geometría vacía, corta y vértices repetidos no fabrican progreso', () {
    expect(RouteProximity([]).classify(points.first).distanceMeters, isNull);
    expect(NavigationProgress([]).project(points.first).remaining, isEmpty);
    expect(NavigationProgress([]).project(points.first).progress, 0);
    expect(
      RouteProximity([points.first]).classify(points.first).isNearRoute,
      isTrue,
    );
    expect(
      RouteProximity([points.first, points.first])
          .classify(points.last)
          .isNearRoute,
      isFalse,
    );
    final geometry = NavigationProgress([
      points.first,
      points.first,
      points.last,
    ]);
    expect(geometry.project(const LatLng(0, .01)).progress, closeTo(.5, .001));
    expect(
      RouteProximity([points.first, points.first, points.last])
          .classify(const LatLng(0, .01))
          .isNearRoute,
      isTrue,
    );
    expect(
      () => RouteProximity(points, thresholdMeters: -1),
      throwsArgumentError,
    );
  });
}
