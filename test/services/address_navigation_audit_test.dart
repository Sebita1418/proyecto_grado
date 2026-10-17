import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/services/address_query.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';
import 'package:transporte_inteligente/models/address_precision.dart';

void main() {
  for (final input in [
    'Cra4 # 48-25, Floridablanca',
    'Cra.4 # 48-25, Floridablanca',
    'Carrera 4 # 48-25, Floridablanca',
  ]) {
    test('normaliza abreviatura sin espacio: $input', () {
      final q = AddressQuery(input);
      expect(q.primaryRoad, 'Carrera 4');
      expect(q.houseNumber, '48-25');
      expect(q.locality, 'Floridablanca');
    });
  }
  test('placa incompleta mantiene contexto sin precisión específica', () {
    final q = AddressQuery('Calle 52 # 3, Floridablanca');
    expect(q.primaryRoad, 'Calle 52');
    expect(q.incompleteNumber, '3');
    expect(q.houseNumber, isNull);
    expect(q.locality, 'Floridablanca');
    expect(q.variants, [
      'Calle 52 # 3, Floridablanca',
      'Calle 52, Floridablanca',
    ]);
    expect(
      q.precisionFor('Calle 52', '3', 'Floridablanca'),
      AddressPrecision.approximate,
    );
    expect(AddressQuery('Carrera 4 Giron').hasCity, isTrue);
  });
  test('error de digitación no se convierte en placa inventada', () {
    final q = AddressQuery('Carera 4 # 48-25');
    expect(q.kind, AddressQueryKind.place);
    expect(q.normalized, 'Carera 4 # 48-25');
  });
  final records = jsonDecode(
    File('test/fixtures/address-provider-audit.json').readAsStringSync(),
  ) as List;
  test('Photon reconoce vía highway distinta sin acreditar placa', () async {
    final record = records.firstWhere(
      (r) =>
          r['query'] == 'Carrera 4 # 48-25, Bucaramanga, Santander, Colombia' &&
          r['provider'] == 'Photon',
    );
    final service = PlaceSuggestionService(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode(record['body']),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final candidates = await service.search('Cra 4 # 48-25, Bucaramanga');
    expect(candidates, isNotEmpty);
    expect(candidates.first.road, 'Carrera 48');
    expect(candidates.first.precision, AddressPrecision.approximate);
    expect(
      AddressQuery('Cra 4 # 48-25')
          .compatibility(candidates.first.road, candidates.first.houseNumber),
      0,
    );
    final first = record['body']['features'][0]['geometry']['coordinates'];
    expect(candidates.first.latitude, first[1]);
    expect(candidates.first.longitude, first[0]);
    service.dispose();
  });
  for (final query in [
    'Carrera 4 # 48-25, Floridablanca',
    'Calle 52 # 3, Floridablanca',
    'Calle 45 con Carrera 27, Bucaramanga',
    'PC System',
  ]) {
    test('reproduce evidencia Nominatim: $query', () async {
      final record = records.firstWhere(
        (r) => r['query'] == query && r['provider'] == 'Nominatim',
      );
      final service = GeocodingService(
        requestInterval: Duration.zero,
        client: MockClient((request) async {
          expect(request.url.queryParameters['limit'], '5');
          return http.Response(
            jsonEncode(record['body']),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final candidates = await service.searchCandidates(query);
      if (query.startsWith('Calle 45')) {
        expect(candidates, isEmpty);
      } else {
        expect(candidates, isNotEmpty);
        expect(
          candidates.every((c) => c.precision != AddressPrecision.specific),
          isTrue,
        );
        final first = (record['body'] as List).first;
        expect(candidates.first.latitude, double.parse(first['lat']));
        expect(candidates.first.longitude, double.parse(first['lon']));
      }
      service.dispose();
    });
  }
}
