import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/services/municipal_boundary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'asset oficial identifica municipio 68001 y conserva todos sus vértices',
    () async {
      final service = MunicipalBoundaryService(
        allowedMunicipalities: [
          MunicipalBoundaryService.operationalMunicipalities.first,
        ],
      ); // Bucaramanga-only regression.
      await service.load();
      expect(service.loadError, isNull);
      expect(service.available, isTrue);
      expect(service.polygons, hasLength(1));
      expect(service.polygons.single, hasLength(1));
      expect(service.polygons.single.single, hasLength(4436));
      expect(
        service.assess(service.polygons.single.single.first).coverage,
        MunicipalCoverage.inside,
      );
    },
  );

  test('puntos reales con procedencia OSM: UIS/parque dentro, municipios vecinos fuera', () async {
    final service = MunicipalBoundaryService(
      allowedMunicipalities: [
        MunicipalBoundaryService.operationalMunicipalities.first,
      ],
    );
    await service.load();
    final points = jsonDecode(
      await File('test/fixtures/boundary-reference-points.json').readAsString(),
    ) as List;
    expect(points, hasLength(5));
    for (var index = 0; index < points.length; index++) {
      final record = points[index];
      expect(
        record['source'],
        startsWith('https://nominatim.openstreetmap.org/search?'),
      );
      final result = (record['results'] as List).single;
      final point = LatLng(
        double.parse(result['lat']),
        double.parse(result['lon']),
      );
      expect(
        service.assess(point).coverage,
        index < 2 ? MunicipalCoverage.inside : MunicipalCoverage.outside,
        reason: record['query'],
      );
    }
  });
}
