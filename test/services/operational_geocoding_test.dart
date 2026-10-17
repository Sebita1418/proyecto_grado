import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';
import 'package:transporte_inteligente/services/municipal_boundary_service.dart';

import '../support/operational_coverage_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MunicipalBoundaryService boundary;
  late Map<String, LatLng> points;
  setUpAll(() async {
    boundary = MunicipalBoundaryService();
    await boundary.load();
    points = await operationalReferencePoints();
  });
  for (final photon in [true, false]) {
    for (final municipality in ['Girón', 'Floridablanca', 'Bucaramanga']) {
      test(
        '${photon ? "Photon" : "Nominatim"} usa contexto GPS verificado $municipality',
        () async {
          final point =
              points[municipality == 'Bucaramanga'
                  ? 'Parque Santander'
                  : municipality]!;
          final client = MockClient((request) async {
            if (photon) {
              expect(
                request.url.queryParameters['q'],
                'Calle 36 15-20, $municipality, Santander, Colombia',
              );
            } else {
              expect(request.url.queryParameters['city'], municipality);
              expect(request.url.queryParameters['street'], '15-20 Calle 36');
              expect(request.url.queryParameters.containsKey('q'), isFalse);
            }
            final body = photon
                ? {
                    'features': [
                      {
                        'geometry': {
                          'coordinates': [point.longitude, point.latitude],
                        },
                        'properties': {
                          'street': 'Calle 36',
                          'city': municipality,
                        },
                      },
                    ],
                  }
                : [
                    {
                      'lat': '${point.latitude}',
                      'lon': '${point.longitude}',
                      'display_name': 'Referencia, $municipality',
                      'address': {'road': 'Calle 36', 'city': municipality},
                    },
                  ];
            return http.Response(
              jsonEncode(body),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          });
          if (photon) {
            final service = PlaceSuggestionService(
              client: client,
              boundaryService: boundary,
            )..searchBias = point;
            final result = (await service.search('Cl 36 15-20')).single;
            expect(result.coverage.permitted, isTrue);
            expect(result.coverage.municipalityName, municipality);
            service.dispose();
          } else {
            final service = GeocodingService(
              client: client,
              boundaryService: boundary,
              requestInterval: Duration.zero,
            )..searchBias = point;
            final result = (await service.searchCandidates('Cl 36 15-20'))
                .single;
            expect(result.coverage.permitted, isTrue);
            expect(result.coverage.municipalityName, municipality);
            service.dispose();
          }
          client.close();
        },
      );
    }
  }
  test(
    'ciudad explícita conserva destino Bucaramanga con GPS de Girón',
    () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['q'], 'Carrera 27, Bucaramanga');
        final point = points['Parque Santander']!;
        return http.Response(
          jsonEncode([
            {
              'lat': '${point.latitude}',
              'lon': '${point.longitude}',
              'display_name': 'Referencia, Bucaramanga',
              'address': {'city': 'Bucaramanga'},
            },
          ]),
          200,
        );
      });
      final service = GeocodingService(
        client: client,
        boundaryService: boundary,
        requestInterval: Duration.zero,
      )..searchBias = points['Girón'];
      expect(
        (await service.search('Cra 27, Bucaramanga'))!
            .coverage
            .municipalityCode,
        '68001',
      );
      client.close();
      service.dispose();
    },
  );
  test(
    'nombre textual no autoriza Piedecuesta ni cambia el municipio geométrico',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'features': [
              for (final name in ['Girón', 'Piedecuesta'])
                {
                  'geometry': {
                    'coordinates': [
                      points[name]!.longitude,
                      points[name]!.latitude,
                    ],
                  },
                  'properties': {'name': 'Lugar $name', 'city': 'Bucaramanga'},
                },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      final service = PlaceSuggestionService(
        client: client,
        boundaryService: boundary,
      );
      final results = await service.search('Lugar');
      expect(results.first.coverage.municipalityName, 'Girón');
      expect(results.last.coverage.coverage, MunicipalCoverage.outside);
      client.close();
      service.dispose();
    },
  );
}
