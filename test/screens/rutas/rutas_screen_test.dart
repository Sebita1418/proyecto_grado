import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/screens/rutas/rutas_screen.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';

http.Response suggestion(String name) => http.Response(
  jsonEncode({
    'type': 'FeatureCollection',
    'features': [
      {
        'geometry': {
          'coordinates': [-73.12, 7.12],
        },
        'properties': {'name': name},
      },
    ],
  }),
  200,
);

void main() {
  late List<String> geocodingQueries;
  late List<String> suggestionQueries;

  Future<void> mount(
    WidgetTester tester, {
    Future<http.Response> Function(http.Request)? photon,
    Future<http.Response> Function(http.Request)? nominatim,
  }) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    geocodingQueries = [];
    suggestionQueries = [];
    final geocodingClient = MockClient((request) async {
      geocodingQueries.add(request.url.queryParameters['q']!);
      if (nominatim != null) return nominatim(request);
      return http.Response(
        '[{"lat":"7.13","lon":"-73.11","display_name":"Encontrado"}]',
        200,
      );
    });
    final photonClient = MockClient((request) async {
      suggestionQueries.add(request.url.queryParameters['q']!);
      if (photon != null) return photon(request);
      return suggestion(request.url.queryParameters['q']!);
    });
    addTearDown(geocodingClient.close);
    addTearDown(photonClient.close);
    await tester.pumpWidget(
      MaterialApp(
        home: RutasScreen(
          loadRoutes: () async => [],
          geocodingService: GeocodingService(client: geocodingClient),
          placeSuggestionService: PlaceSuggestionService(client: photonClient),
        ),
      ),
    );
    await tester.pump();
  }

  Finder field(int index) => find.byType(TextField).at(index);
  RouteMap map(WidgetTester tester) =>
      tester.widget<RouteMap>(find.byType(RouteMap));

  testWidgets('errores de búsqueda y localización no exponen proveedores', (
    tester,
  ) async {
    await mount(
      tester,
      photon: (_) async => http.Response('internal Photon', 503),
      nominatim: (_) async => http.Response('internal Nominatim', 503),
    );
    await tester.enterText(field(0), 'Origen');
    await tester.enterText(field(1), 'Destino');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    expect(
      find.text('No fue posible buscar lugares. Intenta de nuevo.'),
      findsNWidgets(2),
    );
    expect(find.text('Calcular ruta'), findsNothing);
    await tester.tap(find.text('Mostrar puntos'));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('No fue posible localizar los puntos. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(find.textContaining('HTTP'), findsNothing);
    expect(find.text('Localizando...'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('error de carga muestra mensaje humano y reintento', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RutasScreen(
          loadRoutes: () async =>
              throw Exception('HTTP 500 {internal database}'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('No fue posible cargar las rutas.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('HTTP'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('debounce por campo, mínimo tres y respuestas obsoletas', (
    tester,
  ) async {
    final old = Completer<http.Response>();
    await mount(
      tester,
      photon: (request) async {
        return request.url.queryParameters['q'] == 'Par'
            ? old.future
            : suggestion(request.url.queryParameters['q']!);
      },
    );
    await tester.enterText(field(0), 'Pa');
    await tester.pump(const Duration(milliseconds: 500));
    expect(suggestionQueries, isEmpty);
    await tester.enterText(field(0), 'Par');
    await tester.pump(const Duration(milliseconds: 449));
    expect(suggestionQueries, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(suggestionQueries, ['Par']);
    await tester.enterText(field(0), 'Parque');
    await tester.enterText(field(1), 'Universidad');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    old.complete(suggestion('Obsoleta'));
    await tester.pump();
    expect(find.widgetWithText(ListTile, 'Obsoleta'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Parque'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Universidad'), findsOneWidget);
    expect(geocodingQueries, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('selección Photon evita fallback y editar invalida coordenadas', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(field(0), 'Parque');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'Parque'));
    await tester.pump();
    await tester.enterText(field(1), 'Universidad');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'Universidad'));
    await tester.pump();
    final controller = tester.widget<TextField>(field(0)).controller!;
    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    await tester.tap(find.text('Mostrar puntos'));
    await tester.pump();
    expect(geocodingQueries, isEmpty);
    expect(map(tester).markers, hasLength(2));
    expect(map(tester).polylines, isEmpty);
    await tester.enterText(field(0), 'Otro lugar');
    await tester.pump();
    expect(map(tester).markers, hasLength(1));
    await tester.tap(find.text('Mostrar puntos'));
    await tester.pump();
    await tester.pump();
    expect(geocodingQueries, ['Otro lugar']);
    expect(map(tester).markers, hasLength(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('tap y reinicio preservan selección sin routing ni red', (
    tester,
  ) async {
    await mount(tester);
    const origin = LatLng(7.12, -73.12);
    const destination = LatLng(7.14, -73.11);
    map(tester).onTap!(origin);
    await tester.pump();
    map(tester).onTap!(destination);
    await tester.pump();
    expect(map(tester).markers.map((marker) => marker.point), [
      origin,
      destination,
    ]);
    await tester.tap(find.text('Mostrar puntos'));
    await tester.pump();
    expect(geocodingQueries, isEmpty);
    expect(suggestionQueries, isEmpty);
    expect(map(tester).polylines, isEmpty);
    await tester.tap(find.text('Reiniciar'));
    await tester.pump();
    expect(tester.widget<TextField>(field(0)).controller!.text, isEmpty);
    expect(tester.widget<TextField>(field(1)).controller!.text, isEmpty);
    expect(map(tester).markers, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dispose cancela debounce y descarta respuesta pendiente', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    await mount(tester, photon: (_) => pending.future);
    await tester.enterText(field(0), 'Parque');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.enterText(field(1), 'Universidad');
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(suggestion('Tardía'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(suggestionQueries, ['Parque']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dispose durante fallback no actualiza pantalla destruida', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    await mount(tester, nominatim: (_) => pending.future);
    await tester.enterText(field(0), 'Origen manual');
    await tester.enterText(field(1), 'Destino manual');
    await tester.tap(find.text('Mostrar puntos'));
    await tester.pump();
    expect(map(tester).onTap, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(http.Response('[]', 200));
    await tester.pump();
    expect(geocodingQueries, ['Origen manual']);
    expect(tester.takeException(), isNull);
  });
}
