import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/models/place_suggestion.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';

class _Suggestions extends PlaceSuggestionService {
  final queries = <String>[];
  final pending = <Completer<List<PlaceSuggestion>>>[];

  @override
  Future<List<PlaceSuggestion>> search(String query) {
    queries.add(query);
    final completer = Completer<List<PlaceSuggestion>>();
    pending.add(completer);
    return completer.future;
  }
}

class _Location extends LocationService {
  @override
  Future<LocationResult> locate() async => const LocationResult(
    LocationStatus.coordinatesObtained,
    coordinates: LatLng(7.1, -73.1),
  );
}

PlaceSuggestion _place(String name, double lat, double lon) =>
    PlaceSuggestion(name: name, description: '', latitude: lat, longitude: lon);

void main() {
  Future<void> panel(WidgetTester tester, _Suggestions suggestions) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: MapSearchPanel(
              currentPosition: const LatLng(7.1, -73.1),
              locationStatus: LocationStatus.coordinatesObtained,
              placeSuggestionService: suggestions,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Home entrega el servicio al flujo de destino', (tester) async {
    final suggestions = _Suggestions();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          locationService: _Location(),
          loadProfile: () async => null,
          placeSuggestionService: suggestions,
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Cacique');
    await tester.pump(const Duration(milliseconds: 450));
    expect(suggestions.queries, ['Cacique']);
    suggestions.pending.single.complete([]);
    await tester.pump();
  });

  testWidgets('mínimo, debounce, resultado y selección conservan coordenadas', (
    tester,
  ) async {
    final suggestions = _Suggestions();
    await panel(tester, suggestions);
    await tester.enterText(find.byType(TextField).last, 'Ca');
    await tester.pump(const Duration(milliseconds: 500));
    expect(suggestions.queries, isEmpty);
    await tester.enterText(find.byType(TextField).last, 'Cacique');
    await tester.pump(const Duration(milliseconds: 449));
    expect(suggestions.queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(suggestions.queries, ['Cacique']);
    suggestions.pending.single.complete([
      _place('Centro Cacique', 7.12, -73.11),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.text('Centro Cacique'), findsOneWidget);
    final panelWidget = tester.widget<MapSearchPanel>(
      find.byType(MapSearchPanel),
    );
    expect(panelWidget.currentPosition, const LatLng(7.1, -73.1));
    await tester.ensureVisible(find.text('Centro Cacique'));
    await tester.tap(find.text('Centro Cacique'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'Centro Cacique',
    );
    expect(suggestions.queries, ['Cacique']);
  });

  testWidgets('consulta final y respuesta obsoleta', (tester) async {
    final suggestions = _Suggestions();
    await panel(tester, suggestions);
    await tester.enterText(find.byType(TextField).last, 'Primera');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField).last, 'Segunda');
    await tester.pump(const Duration(milliseconds: 450));
    expect(suggestions.queries, ['Segunda']);
    await tester.enterText(find.byType(TextField).last, 'Tercera');
    await tester.pump(const Duration(milliseconds: 450));
    expect(suggestions.queries, ['Segunda', 'Tercera']);
    suggestions.pending.last.complete([_place('Vigente', 7.2, -73.2)]);
    await tester.pump();
    suggestions.pending.first.complete([_place('Obsoleta', 7.3, -73.3)]);
    await tester.pump();
    expect(find.text('Vigente'), findsOneWidget);
    expect(find.text('Obsoleta'), findsNothing);
  });

  testWidgets('vacío termina loading; error permite cálculo manual', (
    tester,
  ) async {
    final suggestions = _Suggestions();
    await panel(tester, suggestions);
    await tester.enterText(find.byType(TextField).last, 'Vacío');
    await tester.pump(const Duration(milliseconds: 450));
    suggestions.pending.last.complete([]);
    await tester.pump();
    expect(find.text('Buscando lugares...'), findsNothing);
    await tester.enterText(find.byType(TextField).last, 'Error');
    await tester.pump(const Duration(milliseconds: 450));
    suggestions.pending.last.completeError(
      const PlaceSuggestionException('Fallo de conexión'),
    );
    await tester.pump();
    expect(find.text('Buscando lugares...'), findsNothing);
    expect(
      find.text('No hay sugerencias disponibles. Puedes escribir y calcular.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
