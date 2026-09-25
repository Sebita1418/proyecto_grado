import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/services/route_alternatives_analysis_service.dart';

RouteResult route(double meters, double seconds) => RouteResult(
  origin: const LatLng(7.1, -73.1),
  destination: const LatLng(7.2, -73.2),
  points: const [LatLng(7.1, -73.1), LatLng(7.2, -73.2)],
  distanceMeters: meters,
  durationSeconds: seconds,
);

void main() {
  const service = RouteAlternativesAnalysisService();

  test('lista vacía no fabrica índices ni diferencias', () {
    final result = service.analyze([]);
    expect(result.fastestIndex, isNull);
    expect(result.shortestIndex, isNull);
    expect(result.differences, isEmpty);
  });

  test('una alternativa tiene ambos mínimos y diferencias cero', () {
    final result = service.analyze([route(1200, 90)]);
    expect(result.fastestIndex, 0);
    expect(result.shortestIndex, 0);
    expect(result.differences.single, (extraSeconds: 0.0, extraMeters: 0.0));
  });

  test('más rápida y más corta pueden ser distintas y no ser la primera', () {
    final result = service.analyze([
      route(7400, 1080),
      route(9100, 900),
      route(6000, 1200),
    ]);
    expect(result.fastestIndex, 1);
    expect(result.shortestIndex, 2);
    expect(result.differences, [
      (extraSeconds: 180.0, extraMeters: 1400.0),
      (extraSeconds: 0.0, extraMeters: 3100.0),
      (extraSeconds: 300.0, extraMeters: 0.0),
    ]);
  });

  test('una alternativa puede ser simultáneamente más rápida y más corta', () {
    final result = service.analyze([route(3000, 900), route(2000, 600)]);
    expect(result.fastestIndex, 1);
    expect(result.shortestIndex, 1);
  });

  test('empate de duración conserva la primera mínima sin desempatar por distancia', () {
    final result = service.analyze([
      route(3000, 900),
      route(2000, 600),
      route(1000, 600),
    ]);
    expect(result.fastestIndex, 1);
    expect(result.shortestIndex, 2);
    expect(result.differences[2].extraSeconds, 0);
  });

  test('empate de distancia conserva la primera mínima sin desempatar por duración', () {
    final result = service.analyze([
      route(3000, 900),
      route(2000, 600),
      route(2000, 300),
    ]);
    expect(result.fastestIndex, 2);
    expect(result.shortestIndex, 1);
    expect(result.differences[2].extraMeters, 0);
  });

  test('empate total es estable y diferencias son inmutables', () {
    final routes = [route(1000, 120), route(1000, 120), route(1000, 120)];
    for (var repetition = 0; repetition < 3; repetition++) {
      final result = service.analyze(routes);
      expect(result.fastestIndex, 0);
      expect(result.shortestIndex, 0);
      expect(
        result.differences.every(
          (d) => d.extraSeconds == 0 && d.extraMeters == 0,
        ),
        isTrue,
      );
      expect(() => result.differences.clear(), throwsUnsupportedError);
    }
  });

  test('compara antes de redondear y admite cero', () {
    final result = service.analyze([route(0.5, 0.5), route(0, 0)]);
    expect(result.fastestIndex, 1);
    expect(result.shortestIndex, 1);
    expect(result.differences.first, (extraSeconds: 0.5, extraMeters: 0.5));
  });

  test('no reordena, copia ni altera rutas o geometrías', () {
    final first = route(3000, 900);
    final second = route(1000, 600);
    final routes = List<RouteResult>.unmodifiable([first, second]);
    service.analyze(routes);
    expect(routes[0], same(first));
    expect(routes[1], same(second));
    expect(first.distanceMeters, 3000);
    expect(first.durationSeconds, 900);
    expect(first.points, [first.origin, first.destination]);
  });

  test('rechaza métricas inválidas sin ocultarlas con valores inventados', () {
    for (final invalid in [-1.0, double.nan, double.infinity]) {
      expect(() => service.analyze([route(invalid, 60)]), throwsArgumentError);
      expect(
        () => service.analyze([route(1000, invalid)]),
        throwsArgumentError,
      );
    }
  });
}
