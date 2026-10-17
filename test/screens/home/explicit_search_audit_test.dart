import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/models/geocoding_result.dart';
import 'package:transporte_inteligente/models/place_suggestion.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';

import 'route_flow_test.dart' show ControlledRouting;

class ExplicitGeocoding extends GeocodingService {
  final pending = Completer<List<GeocodingResult>>();
  final queries = <String>[];
  @override
  Future<List<GeocodingResult>> resolve(
    String query, {
    bool Function()? isCurrent,
  }) {
    queries.add(query);
    return pending.future;
  }
}

class ExplicitSuggestions extends PlaceSuggestionService {
  List<PlaceSuggestion> values = [];
  int calls = 0;
  @override
  Future<List<PlaceSuggestion>> search(String query) async {
    calls++;
    return values;
  }
}

void main() {
  for (final scenario in ['ambiguity', 'fallback', 'stale', 'empty', 'error']) {
    testWidgets('confirmación del teclado muestra candidatos: $scenario', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final geo = ExplicitGeocoding(), suggestions = ExplicitSuggestions();
      final routing = ControlledRouting();
      LatLng? selected;
      final records = jsonDecode(
        File('test/fixtures/address-provider-audit.json').readAsStringSync(),
      ) as List;
      final rows =
          records.firstWhere(
                (r) =>
                    r['query'] == 'Carrera 4 # 48-25, Floridablanca' &&
                    r['provider'] == 'Nominatim',
              )['body']
              as List;
      final candidates = [
        for (final r in rows.take(2))
          GeocodingResult(
            latitude: double.parse(r['lat']),
            longitude: double.parse(r['lon']),
            displayName: r['display_name'],
            road: r['address']['road'],
            city: r['address']['town'],
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapSearchPanel(
              currentPosition: const LatLng(7.1, -73.1),
              locationStatus: LocationStatus.coordinatesObtained,
              geocodingService: geo,
              placeSuggestionService: suggestions,
              routingService: routing,
              onDestinationSelected: (point) => selected = point,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).last, 'PC System');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(geo.queries, ['PC System']);
      expect(routing.calls, 0);
      if (scenario == 'stale') {
        await tester.enterText(find.byType(TextField).last, 'Consulta nueva');
      }
      if (scenario == 'fallback') {
        suggestions.values = [
          PlaceSuggestion(
            name: 'Resultado del proveedor',
            description: 'Floridablanca',
            latitude: candidates.first.latitude,
            longitude: candidates.first.longitude,
          ),
        ];
      }
      if (scenario == 'error') {
        geo.pending.completeError(const GeocodingException('HTTP 429'));
      } else {
        geo.pending.complete(
          scenario == 'ambiguity' || scenario == 'stale' ? candidates : [],
        );
      }
      await tester.pumpAndSettle();
      expect(routing.calls, 0);
      if (scenario == 'ambiguity') {
        expect(find.widgetWithText(ListTile, 'Carrera 4'), findsNWidgets(2));
        await tester.ensureVisible(
          find.widgetWithText(ListTile, 'Carrera 4').last,
        );
        await tester.tap(find.widgetWithText(ListTile, 'Carrera 4').last);
        await tester.pump();
        expect(
          selected,
          LatLng(candidates.last.latitude, candidates.last.longitude),
        );
      } else if (scenario == 'fallback') {
        expect(suggestions.calls, 1);
        await tester.ensureVisible(find.text('Resultado del proveedor'));
        await tester.tap(find.text('Resultado del proveedor'));
        await tester.pump();
        expect(
          selected,
          LatLng(candidates.first.latitude, candidates.first.longitude),
        );
      } else if (scenario == 'stale') {
        expect(find.widgetWithText(ListTile, 'Carrera 4'), findsNothing);
        expect(selected, isNull);
      } else {
        expect(
          find.textContaining(
            scenario == 'empty'
                ? 'No se encontró esa dirección'
                : 'No fue posible buscar la dirección',
          ),
          findsOneWidget,
        );
        expect(selected, isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      geo.dispose();
      suggestions.dispose();
      routing.dispose();
    });
  }
}
