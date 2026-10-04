import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';

void main() {
  group('PlaceSuggestionService', () {
    for (final query in [
      'cacique',
      'centro comercial cacique',
      'Clínica Chicamocha',
      'calle 36 # 15-32',
    ]) {
      test('construye URI Photon sin HTTP para "$query"', () {
        final uri = PlaceSuggestionService.buildPhotonUri(query);
        expect(uri.scheme, 'https');
        expect(uri.host, 'photon.komoot.io');
        expect(uri.path, '/api/');
        expect(uri.queryParameters['q'], query);
        expect(uri.queryParameters['lat'], '7.119349');
        expect(uri.queryParameters['lon'], '-73.122742');
        expect(uri.queryParameters['limit'], '5');
        expect(uri.queryParameters.containsKey('lang'), isFalse);
        expect(uri.queryParameters, hasLength(4));
      });
    }

    test('construye el URI Photon con parámetros de texto', () async {
      Uri? requestedUri;
      final service = PlaceSuggestionService(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response('{"features":[]}', 200);
        }),
      );

      expect(await service.search(' centro comercial cacique '), isEmpty);
      final uri = requestedUri!;
      expect(uri.scheme, 'https');
      expect(uri.host, 'photon.komoot.io');
      expect(uri.path, '/api/');
      expect(uri.queryParameters, {
        'q': 'centro comercial cacique',
        'lat': '7.119349',
        'lon': '-73.122742',
        'limit': '5',
      });
      expect(uri.queryParameters.values, everyElement(isA<String>()));
      expect(uri.queryParameters.containsKey('lang'), isFalse);
    });

    test(
      'omite lang=es que el endpoint público rechaza con HTTP 400',
      () async {
        final service = PlaceSuggestionService(
          client: MockClient((request) async {
            if (request.url.queryParameters['lang'] == 'es') {
              return http.Response(
                '{"lang":[{"message":"Language is not supported. Supported are: default, de, en, fr"}]}',
                400,
              );
            }
            return http.Response('''
            {"type":"FeatureCollection","features":[{
              "geometry":{"type":"Point","coordinates":[-73.1072592,7.0992729]},
              "properties":{"name":"Centro Comercial Cacique","city":"Bucaramanga"}
            }]}
          ''', 200);
          }),
        );

        final results = await service.search('centro comercial cacique');
        expect(results.single.name, 'Centro Comercial Cacique');
        expect(results.single.latitude, 7.0992729);
      },
    );
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
        throwsA(
          isA<PlaceSuggestionException>().having(
            (error) => error.failure,
            'failure',
            PlaceSuggestionFailure.timeout,
          ),
        ),
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
      expect(request.url.queryParameters.containsKey('lang'), isFalse);
      expect(request.headers['User-Agent'], contains('TransporteInteligente'));
      expect(results, hasLength(2));
      expect(results.first.name, 'Parque Santander');
      expect(results.first.description, 'Bucaramanga, Santander, Colombia');
      expect(results.first.latitude, 7.1193);
      expect(results.first.longitude, -73.1227);
    });

    test(
      'no consulta Photon para texto vacío o de menos de tres caracteres',
      () async {
        var requests = 0;
        final service = PlaceSuggestionService(
          client: MockClient((_) async {
            requests++;
            return http.Response('{"features":[]}', 200);
          }),
        );
        expect(await service.search('  '), isEmpty);
        expect(await service.search('ab'), isEmpty);
        expect(requests, 0);
      },
    );

    test('clasifica fallo de conectividad del cliente', () async {
      final service = PlaceSuggestionService(
        client: MockClient((_) async => throw http.ClientException('sin red')),
      );
      await expectLater(
        service.search('cacique'),
        throwsA(
          isA<PlaceSuggestionException>().having(
            (error) => error.failure,
            'failure',
            PlaceSuggestionFailure.connectivity,
          ),
        ),
      );
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
          isA<PlaceSuggestionException>()
              .having((error) => error.message, 'message', contains('HTTP 503'))
              .having((error) => error.statusCode, 'statusCode', 503),
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
          throwsA(
            isA<PlaceSuggestionException>().having(
              (error) => error.failure,
              'failure',
              PlaceSuggestionFailure.invalidResponse,
            ),
          ),
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
