import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/mobility_recommendation.dart';
import 'package:transporte_inteligente/mobility/mobility_recommendation_engine.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/services/mobility_preferences_service.dart';
import 'package:transporte_inteligente/widgets/mobility_recommendation_summary.dart';
import 'package:transporte_inteligente/models/geocoding_result.dart';
import 'package:transporte_inteligente/models/place_suggestion.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/services/osrm_routing_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';
import 'package:transporte_inteligente/widgets/route_result_card.dart';
import 'package:transporte_inteligente/widgets/route_alternatives_selector.dart';

const firstRoute = RouteResult(
  origin: LatLng(7.1, -73.1),
  destination: LatLng(7.2, -73.2),
  points: [LatLng(7.1, -73.1), LatLng(7.14, -73.15), LatLng(7.2, -73.2)],
  distanceMeters: 7400,
  durationSeconds: 1080,
);
const secondRoute = RouteResult(
  origin: LatLng(7.1, -73.1),
  destination: LatLng(7.2, -73.2),
  points: [
    LatLng(7.1, -73.1),
    LatLng(7.18, -73.12),
    LatLng(7.19, -73.17),
    LatLng(7.2, -73.2),
  ],
  distanceMeters: 9100,
  durationSeconds: 900,
);

Future<void> tapLabel(WidgetTester tester, String label) async {
  final tile = find.ancestor(
    of: find.text(label),
    matching: find.byType(ListTile),
  );
  await tester.ensureVisible(tile.evaluate().isEmpty ? find.text(label) : tile);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

class FixedLocation extends LocationService {
  @override
  Future<LocationResult> locate() async => const LocationResult(
    LocationStatus.coordinatesObtained,
    coordinates: LatLng(7.1, -73.1),
  );
}

class FixedGeocoding extends GeocodingService {
  @override
  Future<GeocodingResult?> search(String query) async => const GeocodingResult(
    latitude: 7.2,
    longitude: -73.2,
    displayName: 'Destino',
  );
}

class ControlledRouting extends OsrmRoutingService {
  final requests = <Completer<List<RouteResult>>>[];
  Completer<List<RouteResult>> get pending => requests.last;
  int get calls => requests.length;
  void completeSingle(RouteResult route) => pending.complete([route]);
  LatLng? lastOrigin;
  LatLng? lastDestination;
  @override
  Future<RouteResult> route({
    required LatLng origin,
    required LatLng destination,
  }) => throw StateError('Home debe solicitar routeAlternatives');

  @override
  Future<List<RouteResult>> routeAlternatives({
    required LatLng origin,
    required LatLng destination,
  }) {
    requests.add(Completer<List<RouteResult>>());
    lastOrigin = origin;
    lastDestination = destination;
    return pending.future;
  }
}

class FixedSuggestions extends PlaceSuggestionService {
  @override
  Future<List<PlaceSuggestion>> search(String query) async => [
    PlaceSuggestion(
      name: query.startsWith('Origen') ? 'Plaza origen' : 'Plaza destino',
      description: '',
      latitude: query.startsWith('Origen') ? 7.11 : 7.22,
      longitude: query.startsWith('Origen') ? -73.11 : -73.22,
    ),
  ];
}

class FailingSuggestions extends PlaceSuggestionService {
  @override
  Future<List<PlaceSuggestion>> search(String query) async =>
      throw const PlaceSuggestionException('Photon respondió con HTTP 400.');
}

class ForbiddenGeocoding extends GeocodingService {
  @override
  Future<GeocodingResult?> search(String query) async =>
      throw StateError('No debe geocodificar una selección Photon');
}

class ControlledPreferences extends MobilityPreferencesService {
  final pending = Completer<Set<TransportMode>>();
  @override
  Future<Set<TransportMode>> load() => pending.future;
}

class ControlledEngine implements MobilityRecommendationEngine {
  final pending = Completer<MobilityRecommendation>();
  MobilityContext? context;
  List<RouteOption>? options;
  @override
  Future<MobilityRecommendation> recommend(
    MobilityContext context,
    List<RouteOption> options,
  ) {
    this.context = context;
    this.options = options;
    return pending.future;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> panel(
    WidgetTester tester,
    ControlledRouting routing,
    List<RouteResult?> changes, {
    LatLng position = const LatLng(7.1, -73.1),
    MobilityPreferencesService preferences = const MobilityPreferencesService(),
    MobilityRecommendationEngine? engine,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchPanel(
            currentPosition: position,
            locationStatus: LocationStatus.coordinatesObtained,
            routingService: routing,
            preferencesService: preferences,
            recommendationEngine: engine,
            geocodingService: FixedGeocoding(),
            placeSuggestionService: FixedSuggestions(),
            onRouteChanged: changes.add,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> calculate(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).last, 'Destino');
    await tester.ensureVisible(find.text('Calcular ruta'));
    await tester.tap(find.text('Calcular ruta'));
    await tester.pump();
  }

  Future<void> render(WidgetTester tester, ControlledRouting routing) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          locationService: FixedLocation(),
          loadProfile: () async => null,
          geocodingService: FixedGeocoding(),
          routingService: routing,
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Parque');
    await tester.tap(find.text('Calcular ruta'));
    await tester.pump();
  }

  testWidgets(
    'modos guardados con driving permiten sugerencia sin afirmar default',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        MobilityPreferencesService.storageKey: ['driving', 'walking'],
      });
      final routing = ControlledRouting();
      addTearDown(routing.dispose);
      final changes = <RouteResult?>[];
      await panel(tester, routing, changes);
      await calculate(tester);
      routing.pending.complete([firstRoute, secondRoute]);
      await tester.pumpAndSettle();
      expect(changes.last, same(secondRoute));
      expect(find.text('Ruta sugerida'), findsOneWidget);
      expect(find.textContaining('por defecto'), findsNothing);
    },
  );

  testWidgets(
    'modos sin driving conservan entradas, no dibujan ni seleccionan; relee al reintentar',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        MobilityPreferencesService.storageKey: [
          'walking',
          'cycling',
          'publicTransport',
        ],
      });
      final routing = ControlledRouting();
      addTearDown(routing.dispose);
      await render(tester, routing);
      routing.pending.complete([firstRoute, secondRoute]);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Todavía no hay una ruta compatible'),
        findsOneWidget,
      );
      expect(find.byType(MobilityRecommendationSummary), findsNothing);
      expect(find.byType(RouteResultCard), findsNothing);
      expect(tester.widget<RouteMap>(find.byType(RouteMap)).polylines, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'Parque',
      );
      final storage = await SharedPreferences.getInstance();
      await storage.setStringList(MobilityPreferencesService.storageKey, [
        'driving',
      ]);
      await tester.ensureVisible(find.text('Calcular ruta'));
      await tester.tap(find.text('Calcular ruta'));
      await tester.pump();
      routing.completeSingle(firstRoute);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Todavía no hay una ruta compatible'),
        findsNothing,
      );
      expect(
        find.textContaining('Única alternativa vehicular'),
        findsOneWidget,
      );
      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).polylines.single.points,
        firstRoute.points,
      );
    },
  );

  testWidgets(
    'fallo de almacenamiento no se trata como ausencia de preferencias',
    (tester) async {
      final routing = ControlledRouting();
      addTearDown(routing.dispose);
      final preferences = ControlledPreferences();
      final changes = <RouteResult?>[];
      await panel(tester, routing, changes, preferences: preferences);
      await calculate(tester);
      routing.completeSingle(firstRoute);
      await tester.pump();
      preferences.pending.completeError(
        const MobilityPreferencesStorageException(),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No se pudieron leer las preferencias'),
        findsOneWidget,
      );
      expect(find.byType(RouteResultCard), findsNothing);
      expect(find.textContaining('por defecto'), findsNothing);
      expect(changes, [null]);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );

  for (final dispose in [false, true]) {
    testWidgets(
      'preferencias tardías se descartan tras ${dispose ? 'dispose' : 'edición'}',
      (tester) async {
        final routing = ControlledRouting();
        addTearDown(routing.dispose);
        final preferences = ControlledPreferences();
        final changes = <RouteResult?>[];
        await panel(tester, routing, changes, preferences: preferences);
        await calculate(tester);
        routing.completeSingle(firstRoute);
        await tester.pump();
        if (dispose) {
          await tester.pumpWidget(const SizedBox.shrink());
        } else {
          // Programmatic edits also invalidate a pending evaluation.
          tester
                  .widget<TextField>(find.byType(TextField).last)
                  .controller!
                  .text =
              'Otro destino';
          await tester.pump();
        }
        final before = List<RouteResult?>.of(changes);
        preferences.pending.complete({TransportMode.driving});
        await tester.pumpAndSettle();
        expect(changes, before);
        expect(find.byType(MobilityRecommendationSummary), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('motor tardío no reemplaza un cálculo vigente', (tester) async {
    final routing = ControlledRouting();
    addTearDown(routing.dispose);
    final engine = ControlledEngine();
    final changes = <RouteResult?>[];
    await panel(tester, routing, changes, engine: engine);
    await calculate(tester);
    routing.completeSingle(firstRoute);
    await tester.pump();
    expect(engine.options, isNotNull);
    final oldContext = engine.context!;
    final oldOptions = engine.options!;
    await panel(
      tester,
      routing,
      changes,
      engine: engine,
      position: const LatLng(7.11, -73.11),
    );
    await calculate(tester);
    engine.pending.complete(
      await VehicleRecommendationEngine().recommend(oldContext, oldOptions),
    );
    await tester.pump();
    expect(changes, everyElement(isNull));
    expect(find.byType(MobilityRecommendationSummary), findsNothing);
    expect(find.text('Calculando...'), findsOneWidget);
    routing.pending.completeError(
      const OsrmRoutingException('Fin del cálculo vigente'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fin del cálculo vigente'), findsOneWidget);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('alternativas sincronizan Home, mapa y detalles a $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final routing = ControlledRouting();
      addTearDown(routing.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: HomeScreen(
            locationService: FixedLocation(),
            loadProfile: () async => null,
            geocodingService: FixedGeocoding(),
            placeSuggestionService: FixedSuggestions(),
            routingService: routing,
          ),
        ),
      );
      await tester.pump();
      await calculate(tester);
      expect(routing.calls, 1);
      expect(find.text('Calculando...'), findsOneWidget);
      routing.pending.complete([firstRoute, secondRoute]);
      await tester.pumpAndSettle();
      expect(
        tester.widget<RouteResultCard>(find.byType(RouteResultCard)).route,
        same(secondRoute),
      );
      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).polylines.single.points,
        secondRoute.points,
      );
      expect(find.text('Alternativa 2 de 2 seleccionada'), findsOneWidget);
      expect(find.text('Ruta sugerida'), findsOneWidget);
      expect(find.textContaining('por defecto'), findsOneWidget);
      expect(find.text('Ruta recomendada'), findsNothing);
      await tapLabel(tester, 'Cambiar alternativa');
      expect(find.text('Alternativa 1'), findsOneWidget);
      expect(
        find.textContaining('7.4 km · Duración estimada: 18 min'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Alternativa 2'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Alternativa 2'), findsOneWidget);
      expect(
        find.textContaining('9.1 km · Duración estimada: 15 min'),
        findsOneWidget,
      );
      await tapLabel(tester, 'Alternativa 1');
      final card = tester.widget<RouteResultCard>(find.byType(RouteResultCard));
      expect(card.route, same(firstRoute));
      expect(find.text('Ruta sugerida'), findsNothing);
      expect(find.text('Selección manual'), findsOneWidget);
      expect(card.originLabel, 'Tu ubicación actual');
      expect(card.destinationLabel, 'Destino');
      expect(find.text('7.4 km'), findsOneWidget);
      expect(find.text('18 min'), findsOneWidget);
      expect(find.text('9.1 km'), findsNothing);
      expect(find.text('Alternativa 1 de 2 seleccionada'), findsOneWidget);
      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).polylines.single.points,
        firstRoute.points,
      );
      expect(routing.calls, 1);
      await tapLabel(tester, 'Ver detalles');
      expect(find.text('7.4 km'), findsNWidgets(2));
      expect(find.text('18 min'), findsNWidgets(2));
      expect(find.text('Duración estimada'), findsOneWidget);
      Navigator.of(tester.element(find.text('Detalles de la ruta'))).pop();
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Cambiar alternativa');
      await tester.scrollUntilVisible(
        find.text('Alternativa 2'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tapLabel(tester, 'Alternativa 2');
      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).polylines.single.points,
        secondRoute.points,
      );
      expect(routing.calls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'recalcular reemplaza candidatas; error limpia y permite reintentar',
    (tester) async {
      final routing = ControlledRouting();
      addTearDown(routing.dispose);
      final changes = <RouteResult?>[];
      await panel(tester, routing, changes);
      await calculate(tester);
      routing.pending.complete([firstRoute, secondRoute]);
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Cambiar alternativa');
      await tapLabel(tester, 'Alternativa 1');
      expect(changes, [null, secondRoute, firstRoute]);
      await tapLabel(tester, 'Modificar ruta');
      await calculate(tester);
      expect(changes.last, isNull);
      expect(find.byType(RouteAlternativesSelector), findsNothing);
      routing.completeSingle(firstRoute);
      await tester.pumpAndSettle();
      expect(find.text('Se recibió una sola ruta vehicular.'), findsOneWidget);
      expect(find.text('Cambiar alternativa'), findsNothing);
      expect(
        tester.widget<RouteResultCard>(find.byType(RouteResultCard)).route,
        same(firstRoute),
      );
      await tapLabel(tester, 'Modificar ruta');
      await calculate(tester);
      routing.pending.completeError(
        const OsrmRoutingException('Servicio no disponible'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Servicio no disponible'), findsOneWidget);
      expect(find.byType(RouteAlternativesSelector), findsNothing);
      expect(find.byType(RouteResultCard), findsNothing);
      expect(changes.last, isNull);
      expect(find.text('Calculando...'), findsNothing);
      await calculate(tester);
      routing.completeSingle(secondRoute);
      await tester.pumpAndSettle();
      expect(changes.last, same(secondRoute));
      expect(routing.calls, 4);
    },
  );

  for (final oldFails in [false, true]) {
    testWidgets(
      'GPS invalida solicitud; respuesta obsoleta (error=$oldFails) no reemplaza actual',
      (tester) async {
        final routing = ControlledRouting();
        addTearDown(routing.dispose);
        final changes = <RouteResult?>[];
        await panel(tester, routing, changes);
        await calculate(tester);
        final oldRequest = routing.pending;
        await panel(
          tester,
          routing,
          changes,
          position: const LatLng(7.11, -73.11),
        );
        await calculate(tester);
        expect(routing.calls, 2);
        routing.completeSingle(secondRoute);
        await tester.pumpAndSettle();
        final currentChanges = List<RouteResult?>.of(changes);
        if (oldFails) {
          oldRequest.completeError(
            const OsrmRoutingException('Error obsoleto'),
          );
        } else {
          oldRequest.complete([firstRoute, secondRoute]);
        }
        await tester.pumpAndSettle();
        expect(changes, currentChanges);
        expect(
          tester.widget<RouteResultCard>(find.byType(RouteResultCard)).route,
          same(secondRoute),
        );
        expect(
          find.text('Se recibió una sola ruta vehicular.'),
          findsOneWidget,
        );
        expect(find.text('Error obsoleto'), findsNothing);
        expect(find.text('Calculando...'), findsNothing);
      },
    );
  }

  testWidgets('respuesta obsoleta no termina la carga vigente', (tester) async {
    final routing = ControlledRouting();
    addTearDown(routing.dispose);
    final changes = <RouteResult?>[];
    await panel(tester, routing, changes);
    await calculate(tester);
    final oldRequest = routing.pending;
    await panel(tester, routing, changes, position: const LatLng(7.11, -73.11));
    await calculate(tester);
    final currentChanges = List<RouteResult?>.of(changes);
    oldRequest.complete([firstRoute, secondRoute]);
    await tester.pump();
    expect(changes, currentChanges);
    expect(find.text('Calculando...'), findsOneWidget);
    expect(find.byType(RouteAlternativesSelector), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    routing.completeSingle(secondRoute);
    await tester.pumpAndSettle();
    expect(changes.last, same(secondRoute));
    expect(find.text('Calculando...'), findsNothing);
  });

  testWidgets('GPS invalida lista y cierra selector abierto', (tester) async {
    final routing = ControlledRouting();
    addTearDown(routing.dispose);
    final changes = <RouteResult?>[];
    await panel(tester, routing, changes);
    await calculate(tester);
    routing.pending.complete([firstRoute, secondRoute]);
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Cambiar alternativa');
    await panel(tester, routing, changes, position: const LatLng(7.11, -73.11));
    await tester.pumpAndSettle();
    expect(find.text('Alternativas de ruta vehicular'), findsNothing);
    expect(find.byType(RouteAlternativesSelector), findsNothing);
    expect(find.byType(RouteResultCard), findsNothing);
    expect(changes.last, isNull);
    expect(routing.calls, 1);
  });

  testWidgets('dispose descarta una consulta pendiente', (tester) async {
    final routing = ControlledRouting();
    addTearDown(routing.dispose);
    final changes = <RouteResult?>[];
    await panel(tester, routing, changes);
    await calculate(tester);
    final beforeDispose = List<RouteResult?>.of(changes);
    await tester.pumpWidget(const SizedBox.shrink());
    routing.pending.complete([firstRoute, secondRoute]);
    await tester.pumpAndSettle();
    expect(changes, beforeDispose);
    expect(tester.takeException(), isNull);
  });

  testWidgets('respuesta vacía no fabrica rutas', (tester) async {
    final routing = ControlledRouting();
    addTearDown(routing.dispose);
    final changes = <RouteResult?>[];
    await panel(tester, routing, changes);
    await calculate(tester);
    routing.pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('El servicio no devolvió una ruta.'), findsOneWidget);
    expect(find.byType(RouteResultCard), findsNothing);
    expect(find.byType(RouteAlternativesSelector), findsNothing);
    expect(changes, [null]);
  });

  for (final fieldIndex in [0, 1]) {
    final fieldName = fieldIndex == 0 ? 'origen' : 'destino';
    testWidgets(
      'cursor conserva selección y ruta; editar invalida $fieldName',
      (tester) async {
        final routing = ControlledRouting();
        final geocoding = FixedGeocoding();
        final suggestions = FixedSuggestions();
        addTearDown(routing.dispose);
        addTearDown(geocoding.dispose);
        addTearDown(suggestions.dispose);
        final changes = <RouteResult?>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapSearchPanel(
                currentPosition: null,
                locationStatus: LocationStatus.permissionDenied,
                geocodingService: geocoding,
                placeSuggestionService: suggestions,
                routingService: routing,
                onRouteChanged: changes.add,
              ),
            ),
          ),
        );
        for (final entry in ['Origen', 'Destino'].asMap().entries) {
          await tester.enterText(
            find.byType(TextField).at(entry.key),
            entry.value,
          );
          await tester.pump(const Duration(milliseconds: 450));
          await tester.pump();
          final place = find.text(
            entry.key == 0 ? 'Plaza origen' : 'Plaza destino',
          );
          await tester.ensureVisible(place);
          await tester.tap(place);
          await tester.pump();
        }
        final controller = tester
            .widget<TextField>(find.byType(TextField).at(fieldIndex))
            .controller!;
        controller.selection = const TextSelection.collapsed(offset: 0);
        await tester.pump();
        expect(find.text('Buscando lugares...'), findsNothing);
        await tester.ensureVisible(find.text('Calcular ruta'));
        await tester.tap(find.text('Calcular ruta'));
        await tester.pump();
        expect(routing.calls, 1);
        expect(routing.lastOrigin, const LatLng(7.11, -73.11));
        expect(routing.lastDestination, const LatLng(7.22, -73.22));

        controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 3,
        );
        await tester.pump();
        expect(find.text('Calculando...'), findsOneWidget);
        const result = RouteResult(
          origin: LatLng(7.11, -73.11),
          destination: LatLng(7.22, -73.22),
          points: [LatLng(7.11, -73.11), LatLng(7.22, -73.22)],
          distanceMeters: 1000,
          durationSeconds: 120,
        );
        routing.pending.complete([result, secondRoute]);
        await tester.pump();
        expect(find.byType(RouteResultCard), findsOneWidget);
        expect(
          tester
              .widget<RouteAlternativesSelector>(
                find.byType(RouteAlternativesSelector),
              )
              .alternatives,
          [result, secondRoute],
        );
        expect(changes, [null, result]);

        controller.selection = const TextSelection.collapsed(offset: 1);
        controller.value = controller.value.copyWith(
          composing: const TextRange(start: 0, end: 2),
        );
        await tester.pump();
        expect(find.byType(RouteResultCard), findsOneWidget);
        expect(
          tester
              .widget<RouteAlternativesSelector>(
                find.byType(RouteAlternativesSelector),
              )
              .alternatives,
          [result, secondRoute],
        );
        expect(changes, [null, result]);

        await tester.ensureVisible(find.text('Modificar ruta'));
        await tester.tap(find.text('Modificar ruta'));
        await tester.pump();
        await tester.enterText(
          find.byType(TextField).at(fieldIndex),
          'Otro lugar',
        );
        await tester.pump();
        expect(changes, [null, result, null]);
        expect(find.byType(RouteResultCard), findsNothing);
        expect(find.byType(RouteAlternativesSelector), findsNothing);
        expect(find.byType(MobilityRecommendationSummary), findsNothing);
        await tester.ensureVisible(find.text('Calcular ruta'));
        await tester.tap(find.text('Calcular ruta'));
        await tester.pump();
        expect(routing.calls, 2);
        expect(
          routing.lastOrigin,
          fieldIndex == 0 ? const LatLng(7.2, -73.2) : result.origin,
        );
        expect(
          routing.lastDestination,
          fieldIndex == 1 ? const LatLng(7.2, -73.2) : result.destination,
        );
        routing.completeSingle(result);
        await tester.pump();
        expect(
          tester
              .widget<RouteAlternativesSelector>(
                find.byType(RouteAlternativesSelector),
              )
              .alternatives,
          [result],
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('fallo Photon es discreto y permite calcular con Nominatim', (
    tester,
  ) async {
    final routing = ControlledRouting();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              child: MapSearchPanel(
                currentPosition: const LatLng(7.1, -73.1),
                locationStatus: LocationStatus.coordinatesObtained,
                geocodingService: FixedGeocoding(),
                placeSuggestionService: FailingSuggestions(),
                routingService: routing,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).last, 'Cacique');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(
      find.text('No hay sugerencias disponibles. Puedes escribir y calcular.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Calcular ruta'));
    await tester.tap(find.text('Calcular ruta'));
    await tester.pump();
    expect(routing.calls, 1);
    expect(routing.lastDestination, const LatLng(7.2, -73.2));
    routing.completeSingle(
      const RouteResult(
        origin: LatLng(7.1, -73.1),
        destination: LatLng(7.2, -73.2),
        points: [LatLng(7.1, -73.1), LatLng(7.2, -73.2)],
        distanceMeters: 9800,
        durationSeconds: 660,
      ),
    );
    await tester.pump();
    expect(find.text('11 min'), findsOneWidget);
  });
  testWidgets('selecciones Photon manuales evitan geocodificación', (
    tester,
  ) async {
    final routing = ControlledRouting();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: MapSearchPanel(
                currentPosition: null,
                locationStatus: LocationStatus.permissionDenied,
                geocodingService: ForbiddenGeocoding(),
                placeSuggestionService: FixedSuggestions(),
                routingService: routing,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'Origen');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.ensureVisible(find.text('Plaza origen'));
    await tester.tap(find.text('Plaza origen'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Destino');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.ensureVisible(find.text('Plaza destino'));
    await tester.tap(find.text('Plaza destino'));
    await tester.pump();
    await tester.ensureVisible(find.text('Calcular ruta'));
    await tester.tap(find.text('Calcular ruta'));
    await tester.pump();
    expect(routing.lastOrigin, const LatLng(7.11, -73.11));
    expect(routing.lastDestination, const LatLng(7.22, -73.22));
    routing.completeSingle(
      const RouteResult(
        origin: LatLng(7.11, -73.11),
        destination: LatLng(7.22, -73.22),
        points: [LatLng(7.11, -73.11), LatLng(7.22, -73.22)],
        distanceMeters: 1000,
        durationSeconds: 120,
      ),
    );
    await tester.pump();
  });
  testWidgets(
    'loading bloquea duplicados y éxito dibuja geometría y métricas',
    (tester) async {
      final routing = ControlledRouting();
      await render(tester, routing);
      expect(routing.calls, 1);
      expect(find.text('Calculando...'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNull,
      );
      routing.completeSingle(
        const RouteResult(
          origin: LatLng(7.1, -73.1),
          destination: LatLng(7.2, -73.2),
          points: [
            LatLng(7.1, -73.1),
            LatLng(7.14, -73.15),
            LatLng(7.2, -73.2),
          ],
          distanceMeters: 7400,
          durationSeconds: 1080,
        ),
      );
      await tester.pump();
      expect(find.text('7.4 km'), findsOneWidget);
      expect(find.text('18 min'), findsOneWidget);
      expect(find.byType(RouteResultCard), findsOneWidget);
      expect(find.text('Calcular ruta'), findsNothing);
      expect(find.text('Tu ubicación actual'), findsOneWidget);
      expect(find.text('Parque'), findsOneWidget);
      expect(find.byTooltip('Ver ruta completa'), findsOneWidget);
      await tester.tap(find.text('Ver detalles'));
      await tester.pumpAndSettle();
      expect(find.text('Detalles de la ruta'), findsOneWidget);
      expect(find.text('Duración estimada'), findsOneWidget);
      Navigator.of(tester.element(find.text('Detalles de la ruta'))).pop();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RouteMap>(find.byType(RouteMap))
            .polylines
            .single
            .points
            .length,
        3,
      );
      await tester.tap(find.text('Modificar ruta'));
      await tester.pump();
      expect(find.text('Calcular ruta'), findsOneWidget);
      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).polylines,
        isNotEmpty,
      );
      await tester.enterText(find.byType(TextField).last, 'Otro destino');
      await tester.pump();
      expect(tester.widget<RouteMap>(find.byType(RouteMap)).polylines, isEmpty);
      expect(find.text('7.4 km'), findsNothing);
    },
  );

  testWidgets('error termina loading y no dibuja ruta', (tester) async {
    final routing = ControlledRouting();
    await render(tester, routing);
    routing.pending.completeError(
      const OsrmRoutingException('No se encontró una ruta.'),
    );
    await tester.pump();
    expect(find.text('Calculando...'), findsNothing);
    expect(tester.widget<RouteMap>(find.byType(RouteMap)).polylines, isEmpty);
    expect(find.text('No se encontró una ruta.'), findsOneWidget);
  });
}
