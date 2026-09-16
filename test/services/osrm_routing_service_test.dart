import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/services/osrm_routing_service.dart';

const origin = LatLng(7.1, -73.1);
const destination = LatLng(7.2, -73.2);
const validBody = '''
{"code":"Ok","routes":[{"distance":7400,"duration":1080,
"geometry":{"type":"LineString","coordinates":[[-73.1,7.1],[-73.15,7.14],[-73.2,7.2]]}}]}
''';

void main() {
  test(
    'envía contrato OSRM y conserva orden, coordenadas y métricas',
    () async {
      late Uri uri;
      final service = OsrmRoutingService(
        client: MockClient((request) async {
          uri = request.url;
          return http.Response(validBody, 200);
        }),
      );
      final result = await service.route(
        origin: origin,
        destination: destination,
      );
      expect(uri.path, '/route/v1/driving/-73.1,7.1;-73.2,7.2');
      expect(uri.queryParameters, {
        'steps': 'false',
        'alternatives': 'false',
        'overview': 'full',
        'geometries': 'geojson',
      });
      expect(result.points, [origin, const LatLng(7.14, -73.15), destination]);
      expect(result.distanceMeters, 7400);
      expect(result.durationSeconds, 1080);
    },
  );

  Future<void> rejects(String body, String expected) async {
    final service = OsrmRoutingService(
      client: MockClient((_) async => http.Response(body, 200)),
    );
    await expectLater(
      service.route(origin: origin, destination: destination),
      throwsA(
        isA<OsrmRoutingException>().having(
          (e) => e.message,
          'message',
          contains(expected),
        ),
      ),
    );
  }

  test('rechaza HTTP, timeout y error de red', () async {
    final httpError = OsrmRoutingService(
      client: MockClient((_) async => http.Response('', 503)),
    );
    await expectLater(
      httpError.route(origin: origin, destination: destination),
      throwsA(isA<OsrmRoutingException>()),
    );
    final timeout = OsrmRoutingService(
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return http.Response(validBody, 200);
      }),
      timeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      timeout.route(origin: origin, destination: destination),
      throwsA(
        isA<OsrmRoutingException>().having(
          (e) => e.message,
          'message',
          contains('tardó'),
        ),
      ),
    );
    final networkError = OsrmRoutingService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      networkError.route(origin: origin, destination: destination),
      throwsA(isA<OsrmRoutingException>()),
    );
  });

  test('rechaza JSON, code y rutas vacías', () async {
    await rejects('{', 'respuesta');
    await rejects('{"code":"NoRoute"}', 'No se encontró');
    await rejects('{"code":"Ok","routes":[]}', 'no devolvió');
  });

  test('rechaza geometrías ausentes, vacías y coordenadas inválidas', () async {
    await rejects(
      '{"code":"Ok","routes":[{"distance":1,"duration":2}]}',
      'geometría',
    );
    await rejects(
      '{"code":"Ok","routes":[{"distance":1,"duration":2,"geometry":{"type":"LineString","coordinates":[]}}]}',
      'vacía',
    );
    await rejects(
      '{"code":"Ok","routes":[{"distance":1,"duration":2,"geometry":{"type":"LineString","coordinates":[[0,0],[200,95]]}}]}',
      'coordenadas',
    );
    await rejects(
      '{"code":"Ok","routes":[{"distance":1,"duration":2,"geometry":{"type":"LineString","coordinates":[[0,0],["x",1]]}}]}',
      'geometría',
    );
  });

  test('rechaza distancia y duración inválidas', () async {
    await rejects(
      '{"code":"Ok","routes":[{"distance":-1,"duration":2,"geometry":{"type":"LineString","coordinates":[[0,0],[1,1]]}}]}',
      'distancia',
    );
    await rejects(
      '{"code":"Ok","routes":[{"distance":1,"duration":"2","geometry":{"type":"LineString","coordinates":[[0,0],[1,1]]}}]}',
      'duración',
    );
  });

  test('rechaza coordenadas de solicitud inválidas', () async {
    final service = OsrmRoutingService(
      client: MockClient((_) async => http.Response(validBody, 200)),
    );
    await expectLater(
      service.route(origin: const LatLng(95, 0), destination: destination),
      throwsA(isA<OsrmRoutingException>()),
    );
  });
}
