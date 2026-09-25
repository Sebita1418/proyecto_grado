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
import 'package:transporte_inteligente/models/ruta_model.dart';

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
    Future<List<Ruta>> Function()? loadRoutes,
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
          loadRoutes: loadRoutes ?? () async => [],
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

  Future<void> locate(WidgetTester tester) async {
    await tester.enterText(field(0), 'Origen manual');
    await tester.enterText(field(1), 'Destino manual');
    await tester.tap(find.text('Mostrar puntos'));
    await tester.pump();
  }

  http.Response point(double latitude) => http.Response(
    '[{"lat":"$latitude","lon":"-73.11","display_name":"Punto"}]',
    200,
  );

  for (final destinationTimeout in [false, true]) {
    testWidgets(
      'timeout de ${destinationTimeout ? "destino" : "origen"} libera carga y descarta respuesta tardía',
      (tester) async {
        final old = Completer<http.Response>();
        var attempts = 0;
        await mount(
          tester,
          nominatim: (request) {
            attempts++;
            if (attempts == (destinationTimeout ? 2 : 1)) return old.future;
            return Future.value(point(7.25));
          },
        );
        await locate(tester);
        expect(find.text('Localizando…'), findsOneWidget);
        expect(find.text('Calcular ruta'), findsNothing);
        expect(map(tester).onTap, isNull);
        await tester.pump(const Duration(seconds: 9));
        expect(find.text('Localizando…'), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();
        expect(
          find.text('La búsqueda tardó demasiado. Intenta de nuevo.'),
          findsOneWidget,
        );
        expect(find.text('Mostrar puntos'), findsOneWidget);
        expect(map(tester).onTap, isNotNull);
        expect(geocodingQueries.length, destinationTimeout ? 2 : 1);
        await tester.tap(find.text('Mostrar puntos'));
        await tester.pump();
        expect(map(tester).markers, hasLength(2));
        old.complete(point(8.5));
        await tester.pump();
        expect(
          map(tester).markers.every((m) => m.point.latitude == 7.25),
          isTrue,
        );
        expect(find.byType(SnackBar), findsOneWidget);
        expect(map(tester).polylines, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'edición invalida espera y su respuesta no termina una nueva carga',
    (tester) async {
      final old = Completer<http.Response>();
      final current = Completer<http.Response>();
      await mount(
        tester,
        nominatim: (request) {
          final query = request.url.queryParameters['q'];
          if (query == 'Origen manual') return old.future;
          if (query == 'Nuevo origen') return current.future;
          return Future.value(point(7.3));
        },
      );
      await locate(tester);
      // Simula un cambio de entrada externo aunque el formulario esté bloqueado.
      tester.widget<TextField>(field(0)).controller!.text = 'Nuevo origen';
      await tester.pump();
      await tester.tap(find.text('Mostrar puntos'));
      await tester.pump();
      old.complete(point(8.5));
      await tester.pump();
      expect(find.text('Localizando…'), findsOneWidget);
      expect(geocodingQueries, ['Origen manual', 'Nuevo origen']);
      current.complete(point(7.4));
      await tester.pump();
      expect(map(tester).markers.map((m) => m.point.latitude), [7.4, 7.3]);
      expect(find.text('Mostrar puntos'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final destinationFailure in [false, true]) {
    testWidgets(
      'error Nominatim en ${destinationFailure ? "destino" : "origen"} es comprensible y recuperable',
      (tester) async {
        var fail = true;
        await mount(
          tester,
          nominatim: (request) async {
            if (fail &&
                (!destinationFailure ||
                    request.url.queryParameters['q'] == 'Destino manual')) {
              throw StateError('token secreto interno');
            }
            return point(7.2);
          },
        );
        await locate(tester);
        await tester.pump();
        expect(
          find.text('No fue posible localizar los puntos. Intenta de nuevo.'),
          findsOneWidget,
        );
        expect(find.textContaining('secreto'), findsNothing);
        expect(find.text('Mostrar puntos'), findsOneWidget);
        fail = false;
        await tester.tap(find.text('Mostrar puntos'));
        await tester.pump();
        expect(map(tester).markers, hasLength(2));
        expect(map(tester).polylines, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'dispose durante espera de destino descarta respuesta y timeout',
    (tester) async {
      final pending = Completer<http.Response>();
      await mount(
        tester,
        nominatim: (request) =>
            request.url.queryParameters['q'] == 'Destino manual'
            ? pending.future
            : Future.value(point(7.2)),
      );
      await locate(tester);
      expect(geocodingQueries, ['Origen manual', 'Destino manual']);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      pending.complete(point(7.5));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('error Photon no expone detalles y permite fallback manual', (
    tester,
  ) async {
    await mount(
      tester,
      photon: (_) async => http.Response('detalle interno', 503),
    );
    await tester.enterText(field(0), 'Origen manual');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    expect(
      find.text('No fue posible buscar lugares. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(find.textContaining('503'), findsNothing);
    await tester.enterText(field(1), 'Destino manual');
    await tester.tap(find.text('Mostrar puntos'));
    await tester.pump();
    expect(geocodingQueries, ['Origen manual', 'Destino manual']);
    expect(map(tester).markers, hasLength(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  final catalog = [
    Ruta(
      id: '1',
      nombre: 'Línea Norte',
      origen: 'Terminal',
      destino: 'Universidad',
      descripcion: 'Servicio expreso',
      activa: true,
    ),
    Ruta(
      id: '2',
      nombre: 'Circular',
      origen: 'Centro',
      destino: 'Estadio',
      activa: true,
    ),
  ];
  for (final query in [
    'NORTE',
    ' terminal ',
    'Universidad',
    'EXPRESO',
    'sin coincidencias',
  ]) {
    testWidgets('catálogo filtra "$query" y permite limpiar', (tester) async {
      await mount(tester, loadRoutes: () async => catalog);
      await tester.enterText(field(2), query);
      await tester.pump();
      expect(
        find.text(
          query == 'sin coincidencias'
              ? '0 ruta(s) disponible(s)'
              : '1 ruta(s) disponible(s)',
        ),
        findsOneWidget,
      );
      expect(find.text('Circular'), findsNothing);
      expect(
        find.text('Línea Norte'),
        query == 'sin coincidencias' ? findsNothing : findsOneWidget,
      );
      if (query == 'sin coincidencias') {
        expect(
          find.text('No hay rutas que coincidan con la búsqueda'),
          findsOneWidget,
        );
      }
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      expect(find.text('2 ruta(s) disponible(s)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'recargar catálogo conserva consulta y aplica filtro a datos nuevos',
    (tester) async {
      var loads = 0;
      final refreshed = Completer<List<Ruta>>();
      await mount(
        tester,
        loadRoutes: () {
          loads++;
          return loads == 1 ? Future.value(catalog) : refreshed.future;
        },
      );
      await tester.enterText(field(2), 'Norte');
      await tester.pump();
      final refresh = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      refreshed.complete([catalog[1]]);
      await refresh;
      await tester.pump();
      expect(tester.widget<TextField>(field(2)).controller!.text, 'Norte');
      expect(find.text('0 ruta(s) disponible(s)'), findsOneWidget);
      expect(find.text('Circular'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'catálogo informa carga y error sin detalles; reintento recupera',
    (tester) async {
      final pending = Completer<List<Ruta>>();
      var calls = 0;
      await mount(
        tester,
        loadRoutes: () {
          calls++;
          return calls == 1 ? pending.future : Future.value(catalog);
        },
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.completeError(StateError('Supabase secreto'));
      await tester.pump();
      expect(find.text('No fue posible cargar las rutas.'), findsOneWidget);
      expect(find.textContaining('secreto'), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(find.text('2 ruta(s) disponible(s)'), findsOneWidget);
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

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
