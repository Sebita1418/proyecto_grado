import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/models/address_precision.dart';
import 'package:transporte_inteligente/services/address_query.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';

void main() {
  test(
    'municipio de los datos reales de Nominatim conserva perímetro urbano',
    () {
      expect(
        AddressQuery.providerMunicipality(
          'Perímetro Urbano Bucaramanga',
          'Bucaramanga',
        ),
        'Bucaramanga',
      );
      expect(
        AddressQuery.providerMunicipality(null, 'Bucaramanga'),
        'Bucaramanga',
      );
      expect(
        AddressQuery.providerMunicipality('Floridablanca', 'Bucaramanga'),
        'Floridablanca',
      );
      expect(
        AddressQuery.providerMunicipality(
          'Perímetro Urbano Floridablanca',
          'Floridablanca',
        ),
        'Floridablanca',
      );
      expect(AddressQuery.providerMunicipality(null, 'Metropolitana'), isNull);
    },
  );
  for (final input in [
    'Carrera 27 # 45-30',
    'Cra 27 45-30',
    'Kr 27 # 45-30',
    '  kR.  27 # 45 - 30  ',
  ]) {
    test('dirección numerada: $input', () {
      final query = AddressQuery(input);
      expect(query.original, input);
      expect(query.kind, AddressQueryKind.numberedAddress);
      expect(query.houseNumber, '45-30');
      expect(query.providerQuery, endsWith('Bucaramanga, Santander, Colombia'));
    });
  }
  for (final input in ['Calle 45 con Carrera 27', 'Carrera 33 con Calle 48']) {
    test('intersección: $input', () {
      expect(AddressQuery(input).kind, AddressQueryKind.intersection);
      expect(
        AddressQuery(input).precisionFor('Calle 45', null, 'Bucaramanga'),
        AddressPrecision.approximate,
      );
    });
  }
  for (final input in [
    'Calle 36 Café',
    'Carrera 27 Restaurante',
    'Cacique',
    'UIS',
  ]) {
    test('nombre de lugar: $input', () {
      expect(AddressQuery(input).kind, AddressQueryKind.place);
      expect(AddressQuery(input).providerQuery, input);
    });
  }

  test('conserva candidatos ambiguos y cachea la lista completa', () async {
    var calls = 0;
    final service = GeocodingService(
      requestInterval: Duration.zero,
      client: MockClient((request) async {
        calls++;
        expect(request.url.queryParameters['q'], contains('Bucaramanga'));
        return http.Response(
          jsonEncode([
            for (final lat in [7.11, 7.12])
              {
                'lat': '$lat',
                'lon': '-73.12',
                'display_name': 'Carrera 27 # 45-30, Bucaramanga',
                'address': {
                  'road': 'Carrera 27',
                  'house_number': '45-30',
                  'city': 'Bucaramanga',
                },
              },
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final candidates = await service.resolve('Kr 27 # 45-30');
    expect(candidates.length, 2);
    expect(candidates.map((c) => c.latitude), [7.11, 7.12]);
    expect(await service.resolve('Cra 27 # 45-30'), hasLength(2));
    expect(calls, 1);
    service.dispose();
  });

  test(
    'otra ciudad se descarta; ciudad ausente no certifica precisión',
    () async {
      final service = GeocodingService(
        requestInterval: Duration.zero,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode([
              for (final city in [
                'Floridablanca',
                'Girón',
                'Piedecuesta',
                null,
              ])
                {
                  'lat': '7.11',
                  'lon': '-73.12',
                  'display_name': 'Carrera 27',
                  'address': {
                    'road': 'Carrera 27',
                    'house_number': '45-30',
                    'city': city,
                  },
                },
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      final candidates = await service.resolve('Kr 27 # 45-30');
      expect(candidates, hasLength(1));
      expect(candidates.single.precision, AddressPrecision.approximate);
      service.dispose();
    },
  );

  test('timeout de Nominatim se presenta como error del servicio', () async {
    final service = GeocodingService(
      requestInterval: Duration.zero,
      client: MockClient((_) async => throw TimeoutException('sin respuesta')),
    );
    await expectLater(
      service.resolve('Cl 36 15-20'),
      throwsA(isA<TimeoutException>()),
    );
    service.dispose();
  });

  test('Photon descarta coincidencias de municipios vecinos', () async {
    final service = PlaceSuggestionService(
      client: MockClient((request) async {
        expect(
          request.url.queryParameters['q'],
          'Calle 36 15-20, Bucaramanga, Santander, Colombia',
        );
        return http.Response(
          jsonEncode({
            'features': [
              for (final city in [
                'Bucaramanga',
                'Floridablanca',
                'Girón',
                'Piedecuesta',
              ])
                {
                  'geometry': {
                    'coordinates': [-73.12, 7.11],
                  },
                  'properties': {
                    'street': 'Calle 36',
                    'housenumber': '15-20',
                    'city': city,
                  },
                },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    expect((await service.search('Cl 36 15-20')).single.city, 'Bucaramanga');
    service.dispose();
  });
}
