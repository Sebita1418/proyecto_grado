import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/services/osrm_routing_service.dart';
import 'package:transporte_inteligente/services/municipal_boundary_service.dart';

import '../support/boundary_fixtures.dart';
import 'osrm_routing_service_test.dart' show validBody;

void main() {
  for (final scenario in ['origin', 'destination', 'unknown']) {
    test('OSRM no recibe HTTP con cobertura $scenario', () async {
      var calls = 0;
      final boundary = scenario == 'unknown'
          ? MunicipalBoundaryService(
              loader: () async => throw StateError('ausente'),
            )
          : rectangularBoundary(-74, 7, -73, 8);
      final client = MockClient((_) async {
        calls++;
        return http.Response(validBody, 200);
      });
      final service = OsrmRoutingService(
        client: client,
        boundaryService: boundary,
        endpoint: Uri.parse('https://routing.example.test'),
      );
      await expectLater(
        service.route(
          origin: scenario == 'origin'
              ? const LatLng(9, -72)
              : const LatLng(7.1, -73.1),
          destination: scenario == 'destination'
              ? const LatLng(9, -72)
              : const LatLng(7.2, -73.2),
        ),
        throwsA(
          isA<OsrmRoutingException>().having(
            (e) => e.message,
            'cobertura',
            contains(
              scenario == 'unknown'
                  ? 'No se pudo verificar'
                  : 'fuera de la cobertura',
            ),
          ),
        ),
      );
      expect(calls, 0);
      client.close();
      service.dispose();
    });
  }
  test('OSRM conserva tramo externo con extremos dentro', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response(
        validBody.replaceFirst('[-73.15,7.14]', '[-72,9]'),
        200,
      );
    });
    final service = OsrmRoutingService(
      client: client,
      boundaryService: rectangularBoundary(-74, 7, -73, 8),
      endpoint: Uri.parse('https://routing.example.test'),
    );
    final result = await service.route(
      origin: const LatLng(7.1, -73.1),
      destination: const LatLng(7.2, -73.2),
    );
    expect(calls, 1);
    expect(result.points[1], const LatLng(9, -72));
    expect(result.distanceMeters, 7400);
    expect(result.durationSeconds, 1080);
    client.close();
    service.dispose();
  });
}
