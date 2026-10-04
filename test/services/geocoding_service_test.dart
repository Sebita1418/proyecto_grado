import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';

void main() {
  group('GeocodingService', () {
    test(
      'envía los parámetros esperados y obtiene un resultado válido',
      () async {
        late http.Request request;
        final service = GeocodingService(
          client: MockClient((received) async {
            request = received;
            return http.Response(
              '[{"lat":"7.119349","lon":"-73.122742","display_name":"Parque Santander, Bucaramanga"}]',
              200,
            );
          }),
        );

        final result = await service.search(' Parque Santander, Bucaramanga ');

        expect(request.method, 'GET');
        expect(
          request.url.toString().split('?').first,
          'https://nominatim.openstreetmap.org/search',
        );
        expect(request.url.queryParameters, {
          'q': 'Parque Santander, Bucaramanga',
          'format': 'jsonv2',
          'limit': '1',
          'countrycodes': 'co',
        });
        expect(
          request.headers['User-Agent'],
          contains('TransporteInteligente'),
        );
        expect(result?.latitude, 7.119349);
        expect(result?.longitude, -73.122742);
        expect(result?.displayName, 'Parque Santander, Bucaramanga');
      },
    );

    test('devuelve null cuando la lista está vacía', () async {
      final service = GeocodingService(
        client: MockClient((_) async => http.Response('[]', 200)),
      );
      expect(await service.search('Lugar inexistente'), isNull);
    });

    test('informa un código HTTP de error', () async {
      final service = GeocodingService(
        client: MockClient((_) async => http.Response('Error', 429)),
      );
      expect(
        () => service.search('Parque Santander'),
        throwsA(
          isA<GeocodingException>().having(
            (error) => error.message,
            'message',
            contains('HTTP 429'),
          ),
        ),
      );
    });

    test('rechaza JSON inválido y respuestas inesperadas', () async {
      for (final body in ['{', '{}', '[null]']) {
        final service = GeocodingService(
          client: MockClient((_) async => http.Response(body, 200)),
        );
        expect(
          () => service.search('Parque Santander'),
          throwsA(isA<GeocodingException>()),
        );
      }
    });

    test('rechaza coordenadas inválidas', () async {
      for (final coordinates in [
        ['no-es-numero', '-73.1'],
        ['91', '-73.1'],
        ['7.1', '-181'],
        ['NaN', '-73.1'],
      ]) {
        final service = GeocodingService(
          client: MockClient(
            (_) async => http.Response(
              '[{"lat":"${coordinates[0]}","lon":"${coordinates[1]}","display_name":"Lugar"}]',
              200,
            ),
          ),
        );
        expect(
          () => service.search('Lugar'),
          throwsA(isA<GeocodingException>()),
        );
      }
    });
  });
}
