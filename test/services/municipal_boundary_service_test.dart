import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/services/municipal_boundary_service.dart';

Map<String, Object> square([int offset = 0]) => {
  'type': 'Polygon',
  'coordinates': [
    [
      [offset, 0],
      [offset + 10, 0],
      [offset + 10, 10],
      [offset, 10],
      [offset, 0],
    ],
    [
      [offset + 3, 3],
      [offset + 7, 3],
      [offset + 7, 7],
      [offset + 3, 7],
      [offset + 3, 3],
    ],
  ],
};

void main() {
  test('autointersección con área no nula se rechaza', () {
    expect(
      () => MunicipalBoundaryService.fromGeoJson(
        '{"type":"Polygon","coordinates":[[[0,0],[4,4],[0,4],[3,0],[0,0]]]}',
      ),
      throwsFormatException,
    );
  });
  test('hueco exterior y CRS distinto se rechazan', () {
    expect(
      () => MunicipalBoundaryService.fromGeoJson(
        '{"type":"Polygon","coordinates":[[[0,0],[2,0],[2,2],[0,2],[0,0]],[[3,3],[4,3],[4,4],[3,4],[3,3]]]}',
      ),
      throwsFormatException,
    );
    expect(
      () => MunicipalBoundaryService.fromGeoJson(
        '{"type":"Polygon","crs":{"properties":{"name":"EPSG:3857"}},"coordinates":[[[0,0],[2,0],[2,2],[0,2],[0,0]]]}',
      ),
      throwsFormatException,
    );
  });
  test(
    'interior, exterior, hueco y todos los segmentos/vértices de frontera',
    () {
      final service = MunicipalBoundaryService.fromGeoJson(
        jsonEncode(square()),
      );
      for (final p in [
        const LatLng(1, 1),
        const LatLng(0, 0),
        const LatLng(0, 5),
        const LatLng(10, 10),
        const LatLng(5, 3),
      ]) {
        expect(service.assess(p).coverage, MunicipalCoverage.inside);
      }
      for (final p in [
        const LatLng(5, 5),
        const LatLng(-1, 5),
        const LatLng(11, 5),
      ]) {
        expect(service.assess(p).coverage, MunicipalCoverage.outside);
      }
      expect(service.assess(const LatLng(1e-7, 5)).permitted, isTrue);
      expect(service.assess(const LatLng(-1e-7, 5)).permitted, isFalse);
    },
  );
  test('MultiPolygon incluye segunda isla y mantiene huecos', () {
    final service = MunicipalBoundaryService.fromGeoJson(
      jsonEncode({
        'type': 'MultiPolygon',
        'coordinates': [square()['coordinates'], square(20)['coordinates']],
      }),
    );
    expect(service.assess(const LatLng(1, 21)).permitted, isTrue);
    expect(
      service.assess(const LatLng(5, 25)).coverage,
      MunicipalCoverage.outside,
    );
    expect(
      service.assess(const LatLng(1, 15)).coverage,
      MunicipalCoverage.outside,
    );
  });
  test('FeatureCollection y orientación inversa preservan membresía', () {
    final rings = square()['coordinates'] as List;
    final geometry = {
      'type': 'Polygon',
      'coordinates': rings
          .map((ring) => (ring as List).reversed.toList())
          .toList(),
    };
    final service = MunicipalBoundaryService.fromGeoJson(
      jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {'type': 'Feature', 'properties': {}, 'geometry': geometry},
        ],
      }),
    );
    expect(service.assess(const LatLng(1, 1)).permitted, isTrue);
    expect(service.assess(const LatLng(5, 5)).permitted, isFalse);
  });
  test('coordenadas inválidas nunca se validan ni se llaman fuera', () {
    final service = MunicipalBoundaryService.fromGeoJson(jsonEncode(square()));
    for (final pair in [
      [double.nan, 0.0],
      [0.0, double.infinity],
      [91.0, 0.0],
      [0.0, -181.0],
    ]) {
      final result = service.assessCoordinates(pair[0], pair[1]);
      expect(result.invalidCoordinates, isTrue);
      expect(result.coverage, MunicipalCoverage.unknown);
      expect(result.permitted, isFalse);
    }
  });
  for (final source in [
    '{',
    '{}',
    '{"type":"Point","coordinates":[0,0]}',
    '{"type":"FeatureCollection","features":[]}',
    '{"type":"Feature","geometry":null}',
    '{"type":"Polygon","coordinates":[[[0,0],[1,1],[2,2],[0,0]]]}',
    '{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1]]]}',
    '{"type":"Polygon","coordinates":[[[181,0],[182,0],[182,1],[181,0]]]}',
  ]) {
    test('geometría corrupta produce desconocido: $source', () async {
      final service = MunicipalBoundaryService(loader: () async => source);
      await service.load();
      expect(service.available, isFalse);
      expect(service.loadError, isNotNull);
      expect(
        service.assess(const LatLng(1, 1)).coverage,
        MunicipalCoverage.unknown,
      );
    });
  }
  test('archivo ausente, caché de fallo, retry y recuperación', () async {
    var calls = 0;
    final service = MunicipalBoundaryService(
      loader: () async {
        if (++calls == 1) throw StateError('asset ausente');
        return jsonEncode(square());
      },
    );
    await service.load();
    expect(
      service.endpointsMessage(const LatLng(1, 1), const LatLng(1, 2)),
      contains('No se pudo verificar'),
    );
    await service.load();
    expect(calls, 1);
    await service.load(retry: true);
    expect(service.assess(const LatLng(1, 1)).permitted, isTrue);
    expect(service.loadError, isNull);
    expect(calls, 2);
  });
  test('peticiones concurrentes comparten una carga', () async {
    var calls = 0;
    final service = MunicipalBoundaryService(
      loader: () async {
        calls++;
        return jsonEncode(square());
      },
    );
    await Future.wait([service.load(), service.load(), service.load()]);
    expect(calls, 1);
  });
  test(
    'extremos dentro no validan ni rechazan geometría intermedia de ruta',
    () {
      final service = MunicipalBoundaryService.fromGeoJson(
        jsonEncode(square()),
      );
      expect(
        service.endpointsMessage(const LatLng(1, 1), const LatLng(9, 9)),
        isNull,
      );
      expect(
        service.endpointsMessage(const LatLng(1, 1), const LatLng(11, 11)),
        contains('El destino'),
      );
      expect(
        service.endpointsMessage(const LatLng(-1, 1), const LatLng(9, 9)),
        contains('El origen'),
      );
    },
  );
}
