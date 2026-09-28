import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';

import 'colombia_address_resolution_test.dart' show candidate;

void main() {
  for (final usefulAt in [1, 2, 3, 4]) {
    test('progressive resolution: useful response at $usefulAt', () async {
      final requests = <Uri>[];
      final service = GeocodingService(
        requestInterval: Duration.zero,
        client: MockClient((request) async {
          requests.add(request.url);
          return http.Response(
            jsonEncode(
              requests.length == usefulAt ? [candidate(house: '6-51')] : [],
            ),
            200,
          );
        }),
      );
      final results = await service.resolve('Cl 69 # 6-51, Floridablanca');
      expect(requests.length, usefulAt.clamp(1, 3));
      expect(requests.toSet().length, requests.length);
      expect(requests.first.queryParameters['city'], 'Floridablanca');
      expect(requests.first.queryParameters['street'], '6-51 Calle 69');
      expect(results.isEmpty, usefulAt == 4);
      await service.resolve('Calle 69 6-51, Floridablanca');
      expect(requests.length, usefulAt.clamp(1, 3));
    });
  }
  test(
    'cache distinguishes GPS context but ignores it with explicit city',
    () async {
      var calls = 0;
      final service = GeocodingService(
        requestInterval: Duration.zero,
        client: MockClient((_) async {
          calls++;
          return http.Response(jsonEncode([candidate(house: '6-51')]), 200);
        }),
      );
      service.searchBias = const LatLng(7, -73);
      await service.resolve('Cl 69 # 6-51');
      await service.resolve('Calle 69 6-51');
      expect(calls, 1);
      service.searchBias = const LatLng(8, -73);
      await service.resolve('Cl 69 # 6-51');
      expect(calls, 2);
      await service.resolve('Cl 69 # 6-51, Floridablanca');
      service.searchBias = const LatLng(9, -73);
      await service.resolve('Cl 69 # 6-51, Floridablanca');
      expect(calls, 3);
    },
  );
  test('timeout surfaces safely and does not launch more requests', () async {
    var calls = 0;
    final pending = Completer<http.Response>();
    final service = GeocodingService(
      requestInterval: Duration.zero,
      timeout: Duration.zero,
      client: MockClient((_) {
        calls++;
        return pending.future;
      }),
    );
    await expectLater(
      service.resolve('Cl 69 # 6-51'),
      throwsA(isA<TimeoutException>()),
    );
    expect(calls, 1);
    pending.complete(http.Response('[]', 200));
  });
  test('wrong street is not useful and triggers compatible fallback', () async {
    var calls = 0;
    final service = GeocodingService(
      requestInterval: Duration.zero,
      client: MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode([candidate(road: calls == 1 ? 'Calle 70' : 'Calle 69')]),
          200,
        );
      }),
    );
    expect((await service.resolve('Cl 69 # 6-51')).single.road, 'Calle 69');
    expect(calls, 2);
  });
  test('POI keeps one request and its provider coordinates', () async {
    var calls = 0;
    final service = GeocodingService(
      requestInterval: Duration.zero,
      client: MockClient((_) async {
        calls++;
        return http.Response(
          '[{"lat":"7.1","lon":"-73.1","display_name":"UIS"}]',
          200,
        );
      }),
    );
    expect((await service.resolve('UIS')).single.latitude, 7.1);
    expect(calls, 1);
  });
}
