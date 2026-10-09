import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';
import 'package:transporte_inteligente/services/municipal_boundary_service.dart';

import '../support/boundary_fixtures.dart';

void main() {
  test(
    'retry actualiza cobertura cacheada sin repetir petición HTTP',
    () async {
      var fail = true, calls = 0;
      final boundary = MunicipalBoundaryService(
        loader: () async {
          if (fail) throw StateError('ausente');
          return jsonEncode({
            'type': 'Polygon',
            'coordinates': [
              [
                [-74, 7],
                [-73, 7],
                [-73, 8],
                [-74, 8],
                [-74, 7],
              ],
            ],
          });
        },
      );
      final client = MockClient((_) async {
        calls++;
        return http.Response(
          '[{"lat":"7.5","lon":"-73.5","display_name":"Lugar"}]',
          200,
        );
      });
      final service = GeocodingService(
        client: client,
        boundaryService: boundary,
        requestInterval: Duration.zero,
      );
      expect(
        (await service.search('Lugar'))!.coverage.coverage,
        MunicipalCoverage.unknown,
      );
      fail = false;
      await boundary.load(retry: true);
      expect(
        (await service.search('Lugar'))!.coverage.coverage,
        MunicipalCoverage.inside,
      );
      expect(calls, 1);
      client.close();
      service.dispose();
    },
  );
  for (final photon in [true, false]) {
    test(
      '${photon ? "Photon" : "Nominatim"} conserva y clasifica dentro/fuera por coordenadas',
      () async {
        final boundary = rectangularBoundary(-74, 7, -73, 8);
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode(
              photon
                  ? {
                      'features': [
                        for (final lon in [-73.5, -72.5])
                          {
                            'geometry': {
                              'coordinates': [lon, 7.5],
                            },
                            'properties': {
                              'name': 'Lugar',
                              'city': 'Bucaramanga',
                            },
                          },
                      ],
                    }
                  : [
                      for (final lon in [-73.5, -72.5])
                        {
                          'lat': '7.5',
                          'lon': '$lon',
                          'display_name': 'Lugar, Bucaramanga',
                        },
                    ],
            ),
            200,
          ),
        );
        if (photon) {
          final service = PlaceSuggestionService(
            client: client,
            boundaryService: boundary,
          );
          final results = await service.search('Lugar');
          expect(results.map((r) => r.coverage.coverage), [
            MunicipalCoverage.inside,
            MunicipalCoverage.outside,
          ]);
          service.dispose();
        } else {
          final service = GeocodingService(
            client: client,
            boundaryService: boundary,
            requestInterval: Duration.zero,
          );
          final results = await service.searchCandidates('Lugar');
          expect(results.map((r) => r.coverage.coverage), [
            MunicipalCoverage.inside,
            MunicipalCoverage.outside,
          ]);
          service.dispose();
        }
        client.close();
      },
    );
  }
  test(
    'fallo del asset conserva coordenadas reales con estado desconocido',
    () async {
      final boundary = MunicipalBoundaryService(
        loader: () async => throw StateError('ausente'),
      );
      final client = MockClient(
        (_) async => http.Response(
          '[{"lat":"7.5","lon":"-73.5","display_name":"Lugar"}]',
          200,
        ),
      );
      final service = GeocodingService(
        client: client,
        boundaryService: boundary,
        requestInterval: Duration.zero,
      );
      final result = (await service.search('Lugar'))!;
      expect(result.latitude, 7.5);
      expect(result.coverage.coverage, MunicipalCoverage.unknown);
      expect(result.coverage.permitted, isFalse);
      client.close();
      service.dispose();
    },
  );
}
