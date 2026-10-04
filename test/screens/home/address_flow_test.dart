import 'dart:async';

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

import 'route_flow_test.dart' show ControlledRouting, firstRoute, tapLabel;

class EmptyAddressSuggestions extends PlaceSuggestionService {
  @override
  Future<List<PlaceSuggestion>> search(String query) async => [];
}

class AddressGeocoding extends GeocodingService {
  final pending = Completer<GeocodingResult?>();
  final queries = <String>[];
  @override
  Future<GeocodingResult?> search(String query) {
    queries.add(query);
    return pending.future;
  }
}

const address = GeocodingResult(
  latitude: 7.2,
  longitude: -73.2,
  displayName: 'Carrera 27 # 10-15, Bucaramanga, Santander',
  road: 'Carrera 27',
  houseNumber: '10-15',
  city: 'Bucaramanga',
);

void main() {
  for (final scenario in [
    'select',
    'stale',
    'empty',
    'origin',
    'approximate',
    'calculate',
  ]) {
    testWidgets(
      'dirección confirmada $scenario con fallback y coordenadas reales',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final geocoding = AddressGeocoding();
        final routing = ControlledRouting();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapSearchPanel(
                currentPosition: scenario == 'origin'
                    ? null
                    : const LatLng(7.1, -73.1),
                locationStatus: LocationStatus.coordinatesObtained,
                geocodingService: geocoding,
                placeSuggestionService: EmptyAddressSuggestions(),
                routingService: routing,
              ),
            ),
          ),
        );
        final field = scenario == 'origin'
            ? find.byType(TextField).first
            : find.byType(TextField).last;
        await tester.enterText(field, 'Cra 27 # 10-15, Bucaramanga');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(geocoding.queries, isEmpty);
        final action = scenario == 'calculate'
            ? 'Calcular ruta'
            : scenario == 'origin'
            ? 'Buscar dirección de origen'
            : 'Buscar dirección';
        await tester.ensureVisible(find.text(action));
        await tester.tap(find.text(action));
        await tester.pump();
        expect(geocoding.queries, ['Carrera 27 # 10-15, Bucaramanga']);
        expect(
          tester.widget<TextField>(field).controller!.text,
          'Cra 27 # 10-15, Bucaramanga',
        );
        if (scenario == 'stale') await tester.enterText(field, 'UIS');
        geocoding.pending.complete(
          scenario == 'empty'
              ? null
              : scenario == 'approximate'
              ? const GeocodingResult(
                  latitude: 7.2,
                  longitude: -73.2,
                  displayName: 'Carrera 27, Bucaramanga',
                  road: 'Carrera 27',
                  city: 'Bucaramanga',
                )
              : address,
        );
        await tester.pumpAndSettle();
        if (scenario == 'stale') {
          expect(find.text(address.displayName.split(',').first), findsNothing);
        } else if (scenario == 'empty') {
          expect(
            find.textContaining('No se encontró esa dirección'),
            findsOneWidget,
          );
          expect(routing.calls, 0);
        } else {
          expect(routing.calls, 0);
          expect(
            find.textContaining(
              scenario == 'approximate'
                  ? 'Coincidencia aproximada'
                  : 'Coincidencia específica',
            ),
            findsOneWidget,
          );
          await tapLabel(
            tester,
            scenario == 'approximate' ? 'Carrera 27' : 'Carrera 27 # 10-15',
          );
          if (scenario == 'origin') {
            await tester.enterText(find.byType(TextField).last, 'Cacique');
          }
          await tester.ensureVisible(find.text('Calcular ruta'));
          await tester.tap(find.text('Calcular ruta'));
          await tester.pump();
          expect(routing.calls, 1);
          expect(routing.lastDestination, const LatLng(7.2, -73.2));
          expect(
            routing.lastOrigin,
            scenario == 'origin'
                ? const LatLng(7.2, -73.2)
                : const LatLng(7.1, -73.1),
          );
          expect(
            geocoding.queries.length,
            scenario == 'origin'
                ? 2
                : scenario == 'approximate'
                ? 4
                : 1,
          );
          routing.pending.complete([firstRoute]);
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }
}
