import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';

void main() {
  group('PlaceSuggestionService', () {
    test('termina una solicitud que no responde', () async {
      final service = PlaceSuggestionService(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return http.Response('{}', 200);
        }),
        timeout: const Duration(milliseconds: 10),
      );
      expect(
        () => service.search('parque'),
        throwsA(isA<PlaceSuggestionException>()),
      );
    });
    test('consulta Photon y parsea varios resultados', () async {
      late http.Request request;
      final service = PlaceSuggestionService(
        client: MockClient((received) async {
          request = received;
          return http.Response('''
            {
              "type": "FeatureCollection",
              "features": [
                {
                  "type": "Feature",
                  "geometry": {"type": "Point", "coordinates": [-73.1227, 7.1193]},
                  "properties": {
                    "name": "Parque Santander",
                    "city": "Bucaramanga",
                    "state": "Santander",
                    "country": "Colombia"
                  }
                },
                {
                  "type": "Feature",
                  "geometry": {"type": "Point", "coordinates": [-73.1052, 7.0872]},
                  "properties": {
                    "name": "Cacique",
                    "street": "Transversal 93",
                    "city": "Bucaramanga",
                    "country": "Colombia"
                  }
                }
              ]
            }
            ''', 200);
        }),
      );

      final results = await service.search(' parque sant ');

      expect(
        request.url.toString().split('?').first,
        'https://photon.komoot.io/api/',
      );
      expect(request.url.queryParameters['q'], 'parque sant');
      expect(request.url.queryParameters['lat'], '7.119349');
      expect(request.url.queryParameters['lon'], '-73.122742');
      expect(request.url.queryParameters['limit'], '5');
      expect(request.headers['User-Agent'], contains('TransporteInteligente'));
      expect(results, hasLength(2));
      expect(results.first.name, 'Parque Santander');
      expect(results.first.description, 'Bucaramanga, Santander, Colombia');
      expect(results.first.latitude, 7.1193);
      expect(results.first.longitude, -73.1227);
    });

    test('devuelve una lista vacía para un FeatureCollection vacío', () async {
      final service = PlaceSuggestionService(
        client: MockClient(
          (_) async =>
              http.Response('{"type":"FeatureCollection","features":[]}', 200),
        ),
      );

      expect(await service.search('inexistente'), isEmpty);
    });

    test('informa un código HTTP de error', () async {
      final service = PlaceSuggestionService(
        client: MockClient((_) async => http.Response('Error', 503)),
      );

      expect(
        () => service.search('parque'),
        throwsA(
          isA<PlaceSuggestionException>().having(
            (error) => error.message,
            'message',
            contains('HTTP 503'),
          ),
        ),
      );
    });

    test('rechaza JSON inválido y respuestas inesperadas', () async {
      for (final body in ['{', '[]', '{}']) {
        final service = PlaceSuggestionService(
          client: MockClient((_) async => http.Response(body, 200)),
        );

        expect(
          () => service.search('parque'),
          throwsA(isA<PlaceSuggestionException>()),
        );
      }
    });

    test('ignora features sin coordenadas', () async {
      final service = PlaceSuggestionService(
        client: MockClient(
          (_) async => http.Response(
            '''{"features":[{"geometry":{},"properties":{"name":"Lugar"}}]}''',
            200,
          ),
        ),
      );

      expect(await service.search('lugar'), isEmpty);
    });

    test('ignora coordenadas inválidas', () async {
      final service = PlaceSuggestionService(
        client: MockClient(
          (_) async => http.Response('''
          {"features":[
            {"geometry":{"coordinates":[-181,7]},"properties":{"name":"A"}},
            {"geometry":{"coordinates":[-73,"NaN"]},"properties":{"name":"B"}},
            {"geometry":{"coordinates":[-73,91]},"properties":{"name":"C"}}
          ]}
          ''', 200),
        ),
      );

      expect(await service.search('lugar'), isEmpty);
    });
  });
}
