import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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
  final Completer<RouteResult> pending = Completer<RouteResult>();
  int calls = 0;
  LatLng? lastOrigin;
  LatLng? lastDestination;
  @override
  Future<RouteResult> route({
    required LatLng origin,
    required LatLng destination,
  }) {
    calls++;
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

void main() {
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
        routing.pending.complete(result);
        await tester.pump();
        expect(find.byType(RouteResultCard), findsOneWidget);
        expect(changes, [null, result]);

        controller.selection = const TextSelection.collapsed(offset: 1);
        controller.value = controller.value.copyWith(
          composing: const TextRange(start: 0, end: 2),
        );
        await tester.pump();
        expect(find.byType(RouteResultCard), findsOneWidget);
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
    routing.pending.complete(
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
    routing.pending.complete(
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
      routing.pending.complete(
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
      const OsrmRoutingException('OSRM HTTP 503: {internal error}'),
    );
    await tester.pump();
    expect(find.text('Calculando...'), findsNothing);
    expect(tester.widget<RouteMap>(find.byType(RouteMap)).polylines, isEmpty);
    expect(
      find.text(
        'No fue posible calcular la ruta. Revisa los puntos e intenta de nuevo.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('HTTP'), findsNothing);
  });
}
