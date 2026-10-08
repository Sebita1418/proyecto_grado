import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/config/osrm_config.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/routing/routing_capabilities.dart';
import 'package:transporte_inteligente/services/mode_routing_service.dart';
import 'package:transporte_inteligente/services/osrm_routing_service.dart';

import 'osrm_routing_service_test.dart' show origin, destination;

Map<String, Object> route(double seconds, double meters) => {
  'distance': meters,
  'duration': seconds,
  'geometry': {
    'type': 'LineString',
    'coordinates': [
      [-73.1, 7.1],
      [-73.15, 7.14],
      [-73.2, 7.2],
    ],
  },
  'legs': [
    {
      'steps': [
        {
          'distance': meters,
          'duration': seconds,
          'name': 'Test road',
          'maneuver': {
            'type': 'depart',
            'location': [-73.1, 7.1],
          },
        },
      ],
    },
  ],
};
void main() {
  test('configured servers are separate foot and bike graphs, not car URL substitutions', () {
    expect(
      OsrmConfig.walkingEndpoint.toString(),
      'https://routing.openstreetmap.de/routed-foot',
    );
    expect(
      OsrmConfig.cyclingEndpoint.toString(),
      'https://routing.openstreetmap.de/routed-bike',
    );
    expect(OsrmConfig.endpoint.toString(), 'https://router.project-osrm.org');
  });
  test('mode request delegates to correct graph; metrics/alternatives/geometry/steps unchanged', () async {
    final requests = <http.Request>[];
    OsrmRoutingService service(String prefix, double seconds) =>
        OsrmRoutingService(
          endpoint: Uri.parse('https://example.test/$prefix'),
          client: MockClient((request) async {
            requests.add(request);
            expect(
              request.url.path,
              '/$prefix/route/v1/driving/-73.1,7.1;-73.2,7.2',
            );
            expect(request.url.queryParameters['steps'], 'true');
            expect(request.url.queryParameters['alternatives'], 'true');
            expect(
              request.headers['User-Agent'],
              contains('TransporteInteligente'),
            );
            return http.Response(
              jsonEncode({
                'code': 'Ok',
                'routes': [route(seconds, 100), route(seconds + 10, 120)],
              }),
              200,
            );
          }),
        );
    final driving = service('car', 10),
        walking = service('foot', 100),
        cycling = service('bike', 50);
    final provider = ModeRoutingService(
      driving: driving,
      walking: walking,
      cycling: cycling,
    );
    addTearDown(provider.dispose);
    for (final entry in {
      TransportMode.driving: 10,
      TransportMode.walking: 100,
      TransportMode.cycling: 50,
    }.entries) {
      final routes = await provider.route(
        RoutingRequest(
          origin: origin,
          destination: destination,
          mode: entry.key,
        ),
      );
      expect(routes.length, 2);
      expect(routes.first.durationSeconds, entry.value);
      expect(routes.first.distanceMeters, 100);
      expect(routes.first.points.length, 3);
      expect(routes.first.instructions.single.streetName, 'Test road');
    }
    final before = requests.length;
    await expectLater(
      () => provider.route(
        RoutingRequest(
          origin: origin,
          destination: destination,
          mode: TransportMode.publicTransport,
        ),
      ),
      throwsA(
        isA<OsrmRoutingException>().having(
          (e) => e.failure,
          'unsupported',
          RoutingFailure.unsupported,
        ),
      ),
    );
    expect(requests.length, before);
    expect(
      provider.capabilities.supports(TransportMode.publicTransport),
      isFalse,
    );
  });
  test(
    'typed no route, invalid payload, unavailable, network and timeout',
    () async {
      for (final failure in [
        RoutingFailure.noRoute,
        RoutingFailure.invalidResponse,
        RoutingFailure.unavailable,
        RoutingFailure.networkError,
        RoutingFailure.timeout,
      ]) {
        final walking = OsrmRoutingService(
          endpoint: Uri.parse('https://example.test/foot'),
          timeout: const Duration(milliseconds: 5),
          client: MockClient((_) async {
            if (failure == RoutingFailure.networkError) {
              throw http.ClientException('offline');
            }
            if (failure == RoutingFailure.timeout) {
              await Future<void>.delayed(const Duration(milliseconds: 20));
            }
            return http.Response(
              failure == RoutingFailure.noRoute
                  ? '{"code":"NoRoute"}'
                  : failure == RoutingFailure.invalidResponse
                  ? '{'
                  : '{"code":"Ok","routes":[]}',
              failure == RoutingFailure.unavailable ? 503 : 200,
            );
          }),
        );
        final provider = ModeRoutingService(
          driving: OsrmRoutingService(),
          walking: walking,
          enableCycling: false,
        );
        await expectLater(
          provider.route(
            RoutingRequest(
              origin: origin,
              destination: destination,
              mode: TransportMode.walking,
            ),
          ),
          throwsA(
            isA<OsrmRoutingException>().having(
              (e) => e.failure,
              'failure',
              failure,
            ),
          ),
        );
        provider.dispose();
        walking.dispose();
      }
    },
  );
  test('disabled configured mode makes no request', () {
    final provider = ModeRoutingService(
      driving: OsrmRoutingService(),
      enableWalking: false,
      enableCycling: false,
    );
    expect(provider.capabilities.modes, {TransportMode.driving});
    expect(
      () => provider.route(
        RoutingRequest(
          origin: origin,
          destination: destination,
          mode: TransportMode.walking,
        ),
      ),
      throwsA(isA<OsrmRoutingException>()),
    );
    provider.dispose();
  });
}
