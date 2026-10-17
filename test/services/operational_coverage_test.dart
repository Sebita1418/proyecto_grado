import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/services/municipal_boundary_service.dart';

import '../support/operational_coverage_fixtures.dart';

List<List<num>> square(num x) => [
  [x, 0],
  [x + 4, 0],
  [x + 4, 4],
  [x, 4],
  [x, 0],
];
String feature(
  MunicipalTerritory municipality, {
  String? code,
  dynamic geometry,
}) => jsonEncode({
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'properties': {
        'mpio_cdpmp': code ?? municipality.code,
        'mpio_cnmbr': municipality.name.toUpperCase(),
        'mpio_tipo': 'MUNICIPIO',
        'mpio_nano': 2024,
      },
      'geometry':
          geometry ??
          {
            'type': 'Polygon',
            'coordinates': [
              square(
                MunicipalBoundaryService.operationalMunicipalities.indexOf(
                      municipality,
                    ) *
                    10,
              ),
            ],
          },
    },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('tres assets reales conservan identidad, geometría y municipio de referencia', () async {
    final service = MunicipalBoundaryService();
    await service.load();
    expect(service.available, isTrue);
    expect(service.loadErrors, isEmpty);
    expect(service.polygons.map((p) => p.single.length), [4436, 7696, 3165]);
    final points = await operationalReferencePoints();
    for (final pair in {
      'Parque Santander': '68001',
      'Universidad Industrial de Santander': '68001',
      'Girón': '68307',
      'Floridablanca': '68276',
    }.entries) {
      final result = service.assess(points[pair.key]!);
      expect(result.permitted, isTrue, reason: pair.key);
      expect(result.municipalityCode, pair.value);
    }
    expect(
      service.assess(points['Piedecuesta']!).coverage,
      MunicipalCoverage.outside,
    );
    for (final municipality in service.municipalities) {
      final data = jsonDecode(
        await File(municipality.assetPath).readAsString(),
      );
      expect(
        data['features'][0]['properties']['mpio_cdpmp'],
        municipality.code,
      );
    }
  });
  test(
    'unión configurable de municipios sin disolver anillos ni islas',
    () async {
      final service = MunicipalBoundaryService(
        municipalityLoader: (m) async => feature(
          m,
          geometry: m.code == '68001'
              ? {
                  'type': 'Polygon',
                  'coordinates': [
                    square(0),
                    [
                      [1, 1],
                      [2, 1],
                      [2, 2],
                      [1, 2],
                      [1, 1],
                    ],
                  ],
                }
              : m.code == '68307'
              ? {
                  'type': 'MultiPolygon',
                  'coordinates': [
                    [square(10)],
                    [square(30)],
                  ],
                }
              : null,
        ),
      );
      await service.load();
      expect(service.polygons, hasLength(4));
      expect(service.assess(const LatLng(3, 3)).municipalityCode, '68001');
      expect(service.assess(const LatLng(2, 12)).municipalityCode, '68307');
      expect(service.assess(const LatLng(2, 32)).municipalityCode, '68307');
      expect(service.assess(const LatLng(2, 22)).municipalityCode, '68276');
      expect(
        service.assess(const LatLng(1.5, 1.5)).coverage,
        MunicipalCoverage.outside,
      );
      expect(
        service.assess(const LatLng(1.5, 1)).permitted,
        isTrue,
      ); // hole boundary
      expect(
        service.assess(const LatLng(2, 10)).permitted,
        isTrue,
      ); // outer boundary
      expect(
        service.assess(const LatLng(2, 10 - 1e-7)).coverage,
        MunicipalCoverage.outside,
      );
    },
  );
  for (final failure in ['missing', 'wrong-code', 'corrupt-geometry']) {
    test(
      'fallo parcial $failure conserva dentro verificado y nunca infiere fuera',
      () async {
        var fail = true;
        final calls = <String, int>{};
        final service = MunicipalBoundaryService(
          municipalityLoader: (m) async {
            calls[m.code] = (calls[m.code] ?? 0) + 1;
            if (m.code == '68307' && fail) {
              if (failure == 'missing') throw StateError('asset ausente');
              return feature(
                m,
                code: failure == 'wrong-code' ? '68001' : null,
                geometry: failure == 'corrupt-geometry'
                    ? {'type': 'Polygon', 'coordinates': []}
                    : null,
              );
            }
            return feature(m);
          },
        );
        await Future.wait([service.load(), service.load()]);
        expect(service.available, isFalse);
        expect(service.loadErrors.keys, ['68307']);
        expect(service.assess(const LatLng(2, 2)).permitted, isTrue);
        expect(service.assess(const LatLng(2, 22)).permitted, isTrue);
        expect(
          service.assess(const LatLng(2, 12)).coverage,
          MunicipalCoverage.unknown,
        );
        expect(
          service.assess(const LatLng(6, 6)).coverage,
          MunicipalCoverage.unknown,
        );
        await service.load();
        expect(calls['68307'], 1);
        fail = false;
        await service.load(retry: true);
        expect(service.available, isTrue);
        expect(service.assess(const LatLng(2, 12)).municipalityCode, '68307');
        expect(
          service.assess(const LatLng(6, 6)).coverage,
          MunicipalCoverage.outside,
        );
        expect(calls, {'68001': 1, '68307': 2, '68276': 1});
      },
    );
  }
  test(
    'configuración Bucaramanga exclusiva sigue rechazando vecinos',
    () async {
      final service = MunicipalBoundaryService(
        allowedMunicipalities: [
          MunicipalBoundaryService.operationalMunicipalities.first,
        ],
      );
      await service.load();
      final points = await operationalReferencePoints();
      expect(service.assess(points['Parque Santander']!).permitted, isTrue);
      expect(
        service.assess(points['Girón']!).coverage,
        MunicipalCoverage.outside,
      );
      expect(
        service.assess(points['Floridablanca']!).coverage,
        MunicipalCoverage.outside,
      );
    },
  );
  test(
    'frontera compartida devuelve ambos municipios de forma determinista',
    () async {
      final allowed = MunicipalBoundaryService.operationalMunicipalities
          .take(2)
          .toList();
      final service = MunicipalBoundaryService(
        allowedMunicipalities: allowed,
        municipalityLoader: (m) async => feature(
          m,
          geometry: {
            'type': 'Polygon',
            'coordinates': [square(m.code == '68001' ? 0 : 4)],
          },
        ),
      );
      await service.load();
      expect(
        service.assess(const LatLng(2, 4)).municipalities.map((m) => m.code),
        ['68001', '68307'],
      );
    },
  );
}
