import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/models/address_precision.dart';
import 'package:transporte_inteligente/models/geocoding_result.dart';
import 'package:transporte_inteligente/services/address_query.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';

Map<String, Object> candidate({
  String road = 'Calle 69',
  String? house,
  String city = 'Floridablanca',
  double lat = 7.06,
}) => {
  'lat': '$lat',
  'lon': '-73.1',
  'display_name': '$road${house == null ? '' : ' # $house'}, $city',
  'address': {'road': road, 'house_number': ?house, 'city': city},
};
void main() {
  for (final input in ['Calle 69 # 6-51', 'Cl 69 # 6-51', 'Calle 69 6-51']) {
    test('parse completo y original: $input', () {
      final parsed = AddressQuery(input);
      expect(parsed.original, input);
      expect(parsed.primaryRoad, 'Calle 69');
      expect(parsed.secondaryNumber, '6');
      expect(parsed.propertyNumber, '51');
      expect(parsed.locality, isEmpty);
      expect(AddressQuery.forProvider(input), isNot(contains('Bucaramanga')));
    });
  }
  for (final input in [
    'Carrera 27 # 36-14',
    'Carrera 27 36-14',
    'Cra 27 # 36-14',
    'Cr 27 36-14',
  ]) {
    test('parse carrera: $input', () {
      final parsed = AddressQuery(input);
      expect(parsed.primaryRoad, 'Carrera 27');
      expect(parsed.houseNumber, '36-14');
    });
  }
  for (final city in [
    'Floridablanca',
    'Bucaramanga',
    'Girón',
    'Piedecuesta',
    'Bogotá',
  ]) {
    test('conserva ciudad explícita $city en todas las variantes', () {
      final parsed = AddressQuery('Calle 69 # 6-51, $city');
      expect(parsed.locality, city);
      expect(parsed.variants, everyElement(endsWith(', $city')));
      expect(parsed.variants.length, AddressQuery.maxVariants);
    });
  }
  test('orden progresivo conserva placa en tres consultas antes de calle', () {
    expect(AddressQuery('Cl 69 6-51').variants, [
      'Calle 69 # 6-51',
      'Calle 69 6-51',
      'Calle 69 6 51',
      'Calle 69',
    ]);
  });
  for (final input in ['Calle 45 Carrera 27', 'Calle 45 con Carrera 27']) {
    test('intersección conservada sin inventar coordenadas $input', () {
      final parsed = AddressQuery(input);
      expect(parsed.crossingRoad, 'Carrera 27');
      expect(
        parsed.precisionFor('Calle 45', null, 'Bucaramanga'),
        AddressPrecision.approximate,
      );
    });
  }
  test('precisión exige vía, placa y ciudad compatibles', () {
    final query = AddressQuery('Calle 69 # 6-51, Floridablanca');
    expect(
      query.precisionFor('Cl 69', '6-51', 'Floridablanca'),
      AddressPrecision.specific,
    );
    expect(
      query.precisionFor('Calle 69', null, 'Floridablanca'),
      AddressPrecision.approximate,
    );
    expect(
      query.precisionFor('Calle 70', '6-51', 'Floridablanca'),
      AddressPrecision.approximate,
    );
    expect(
      query.precisionFor('Calle 69', '65-1', 'Floridablanca'),
      AddressPrecision.approximate,
    );
    expect(
      query.precisionFor('Calle 69', '6-51', 'Bucaramanga'),
      AddressPrecision.approximate,
    );
    expect(query.precisionFor(null, null, null), AddressPrecision.approximate);
    expect(
      AddressQuery('UIS').precisionFor(null, null, null),
      AddressPrecision.poi,
    );
  });
  test('ranking: compatibilidad, ciudad, proximidad, completitud y orden', () {
    GeocodingResult result(
      String label, {
      String? house,
      String city = 'Floridablanca',
      double lat = 7.06,
    }) => GeocodingResult(
      latitude: lat,
      longitude: -73.1,
      displayName: label,
      road: 'Calle 69',
      houseNumber: house,
      city: city,
    );
    final query = AddressQuery('Calle 69 # 6-51');
    final results = [
      result('street'),
      result('far-full', house: '6-51', lat: 8),
      result('near-full', house: '6-51'),
      result('tie', house: '6-51'),
    ];
    expect(
      query
          .rank(results, bias: const LatLng(7.06, -73.1))
          .map((r) => r.displayName),
      ['near-full', 'tie', 'far-full', 'street'],
    );
    expect(
      AddressQuery('Calle 69 # 6-51, Floridablanca')
          .rank([
            result('wrong', house: '6-51', city: 'Bucaramanga'),
            result('right', house: '6-51'),
          ])
          .first
          .displayName,
      'right',
    );
  });
  test(
    'Nominatim evalúa cinco candidatos y se detiene al encontrar placa',
    () async {
      final requests = <Uri>[];
      final service = GeocodingService(
        requestInterval: Duration.zero,
        client: MockClient((request) async {
          requests.add(request.url);
          expect(request.url.queryParameters['limit'], '5');
          expect(request.url.queryParameters['addressdetails'], '1');
          return http.Response(
            jsonEncode([candidate(), candidate(house: '6-51')]),
            200,
          );
        }),
      );
      final results = await service.resolve('Calle 69 # 6-51, Floridablanca');
      expect(requests.length, 1);
      expect(requests.single.queryParameters.containsKey('viewbox'), isFalse);
      expect(results.first.precision, AddressPrecision.specific);
      expect(results.first.latitude, 7.06);
    },
  );
  test(
    'fallback limitado, estructurado y calle aproximada sin placa inventada',
    () async {
      final requests = <Uri>[];
      final service = GeocodingService(
        requestInterval: Duration.zero,
        client: MockClient((request) async {
          requests.add(request.url);
          return http.Response(jsonEncode([candidate()]), 200);
        }),
      );
      final results = await service.resolve('Calle 69 # 6-51, Floridablanca');
      expect(requests.length, 4);
      expect(requests[1].queryParameters['street'], '6-51 Calle 69');
      expect(requests[1].queryParameters['city'], 'Floridablanca');
      expect(requests[1].queryParameters.containsKey('q'), isFalse);
      expect(requests.last.queryParameters['q'], 'Calle 69, Floridablanca');
      expect(results.length, 1);
      expect(results.single.precision, AddressPrecision.approximate);
      expect(results.single.displayName, isNot(contains('6-51')));
    },
  );
  test(
    'GPS produce viewbox de preferencia, sin imponer municipio ni bounded',
    () async {
      final service = GeocodingService(
        requestInterval: Duration.zero,
        client: MockClient((request) async {
          expect(request.url.queryParameters['viewbox'], startsWith('-73.28'));
          expect(request.url.queryParameters.containsKey('bounded'), isFalse);
          expect(
            request.url.queryParameters['q'],
            isNot(contains('Bucaramanga')),
          );
          return http.Response(jsonEncode([candidate(house: '6-51')]), 200);
        }),
      )..searchBias = const LatLng(7.06, -73.1);
      expect(
        (await service.resolve('Calle 69 # 6-51')).first.precision,
        AddressPrecision.specific,
      );
    },
  );
  test('ciudad explícita no se sustituye por otra del proveedor', () async {
    final service = GeocodingService(
      requestInterval: Duration.zero,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode([candidate(house: '6-51', city: 'Bucaramanga')]),
          200,
        ),
      ),
    );
    expect(await service.resolve('Calle 69 # 6-51, Floridablanca'), isEmpty);
  });
  test(
    'stale detiene nuevas variantes; cero requests si ya estaba obsoleta',
    () async {
      var current = true, calls = 0;
      final service = GeocodingService(
        requestInterval: Duration.zero,
        client: MockClient((_) async {
          calls++;
          current = false;
          return http.Response(jsonEncode([candidate()]), 200);
        }),
      );
      expect(
        await service.resolve('Calle 69 # 6-51', isCurrent: () => current),
        isEmpty,
      );
      expect(calls, 1);
      await service.resolve('Calle 69 # 6-51', isCurrent: () => current);
      expect(calls, 1);
    },
  );
  test('Photon una petición con GPS y clasificación específica', () async {
    var calls = 0;
    final service = PlaceSuggestionService(
      client: MockClient((request) async {
        calls++;
        expect(request.url.host, 'photon.komoot.io');
        expect(request.url.queryParameters['lat'], '7.06');
        expect(request.url.queryParameters['q'], 'Calle 69 # 6-51');
        return http.Response(
          jsonEncode({
            'features': [
              {
                'geometry': {
                  'coordinates': [-73.1, 7.06],
                },
                'properties': {
                  'street': 'Calle 69',
                  'housenumber': '6-51',
                  'city': 'Floridablanca',
                },
              },
            ],
          }),
          200,
        );
      }),
    )..searchBias = const LatLng(7.06, -73.1);
    expect(
      (await service.search('Cl 69 # 6-51')).single.precision,
      AddressPrecision.specific,
    );
    expect(calls, 1);
  });
}
