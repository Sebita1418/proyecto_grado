import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/services/address_query.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';

void main() {
  for (final entry in {
    'Cra. 27': 'Carrera 27',
    'Cr 27': 'Carrera 27',
    'Cl 36': 'Calle 36',
    'Av 5': 'Avenida 5',
    'Diag 8': 'Diagonal 8',
    'Trans 9': 'Transversal 9',
  }.entries) {
    test('normaliza ${entry.key}', () {
      expect(AddressQuery.normalize(entry.key), entry.value);
      expect(AddressQuery.forProvider(entry.key), entry.value);
    });
  }
  for (final query in [
    'Carrera 27',
    'Calle 36',
    'Carrera 33 # 48-21',
    'Carrera 33 con Calle 52',
    'Calle 45 Carrera 27',
  ]) {
    test(
      'contexto local para $query',
      () => expect(AddressQuery.forProvider(query), query),
    );
  }
  for (final query in [
    'Carrera 27 # 10-15, Bucaramanga',
    'Calle 5, Floridablanca',
    'Calle 5 Bogotá',
    'Carrera 33, Medellín',
    'UIS',
    'Cacique',
    'Parque Caracolí',
    'Hospital Internacional',
  ]) {
    test(
      'conserva ciudad o POI: $query',
      () => expect(AddressQuery.forProvider(query), query),
    );
  }
  test(
    'Photon consulta dirección normalizada y muestra numeración real',
    () async {
      final service = PlaceSuggestionService(
        client: MockClient((request) async {
          expect(request.url.host, 'photon.komoot.io');
          expect(
            request.url.queryParameters['q'],
            'Carrera 27 # 10-15, Bucaramanga, Santander, Colombia',
          );
          return http.Response(
            jsonEncode({
              'features': [
                {
                  'geometry': {
                    'coordinates': [-73.12, 7.11],
                  },
                  'properties': {
                    'street': 'Carrera 27',
                    'housenumber': '10-15',
                    'city': 'Bucaramanga',
                    'state': 'Santander',
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      final result = (await service.search('Cra 27 # 10-15')).single;
      expect(result.name, 'Carrera 27 # 10-15');
      expect(result.description, contains('Bucaramanga'));
      expect(result.latitude, 7.11);
      expect(result.longitude, -73.12);
    },
  );
  test('autocomplete vacío nunca llama a Nominatim', () async {
    var calls = 0;
    final service = PlaceSuggestionService(
      client: MockClient((request) async {
        calls++;
        expect(request.url.host, 'photon.komoot.io');
        return http.Response('{"features":[]}', 200);
      }),
    );
    expect(await service.search('Carrera 27'), isEmpty);
    expect(calls, 1);
  });
  test(
    'búsqueda confirmada normaliza y cachea coordenadas de Nominatim',
    () async {
      var calls = 0;
      final service = GeocodingService(
        client: MockClient((request) async {
          calls++;
          expect(
            request.url.queryParameters['q'],
            'Carrera 27 # 10-15, Bucaramanga',
          );
          return http.Response(
            '[{"lat":"7.11","lon":"-73.12","display_name":"Carrera 27, Bucaramanga"}]',
            200,
          );
        }),
      );
      final first = await service.search('Cra 27 # 10-15, Bucaramanga');
      final second = await service.search('Carrera 27 # 10-15, Bucaramanga');
      expect(first?.latitude, 7.11);
      expect(second, same(first));
      expect(calls, 1);
    },
  );
}
