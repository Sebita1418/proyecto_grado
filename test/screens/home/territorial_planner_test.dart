import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/models/geocoding_result.dart';
import 'package:transporte_inteligente/models/place_suggestion.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/services/municipal_boundary_service.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';
import 'package:transporte_inteligente/widgets/navigation_status_card.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';

import '../../navigation/navigation_session_test.dart' show TrackingLocation;
import '../../navigation/navigation_v2_test.dart' show v2Route;
import 'navigation_flow_test.dart' show NavigationGeocoding;

import '../../support/boundary_fixtures.dart';
import 'route_flow_test.dart'
    show ControlledRouting, FixedGeocoding, FixedSuggestions, tapLabel;

class OutsideGeocoding extends GeocodingService {
  @override
  Future<GeocodingResult?> search(String query) async => const GeocodingResult(
    latitude: 9,
    longitude: -72,
    displayName: 'Lugar externo',
  );
}

class OutsideSuggestions extends PlaceSuggestionService {
  @override
  Future<List<PlaceSuggestion>> search(String query) async => const [
    PlaceSuggestion(
      name: 'Lugar externo',
      description: 'Municipio vecino',
      latitude: 9,
      longitude: -72,
    ),
  ];
}

void main() {
  testWidgets('GPS exterior durante navegación informa sin finalizar la ruta', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final gps = TrackingLocation();
    final routing = ControlledRouting();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          initiallyCollapsed: false,
          loadProfile: () async => null,
          locationService: gps,
          routingService: routing,
          boundaryService: rectangularBoundary(-.001, -.001, .021, .001),
          geocodingService: NavigationGeocoding(),
          placeSuggestionService: FixedSuggestions(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Destino');
    await tester.ensureVisible(find.text('Analizar rutas'));
    await tester.tap(find.text('Analizar rutas'));
    await tester.pump();
    routing.pending.complete([v2Route]);
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Iniciar navegación');
    gps.position(const LatLng(.002, .01));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Fuera de la cobertura: ubicación GPS actual'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<NavigationStatusCard>(find.byType(NavigationStatusCard))
          .session
          .isActive,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(gps.updates.close);
  });
  Future<void> act(WidgetTester tester, String label) async {
    final target = label == 'Lugar externo'
        ? find.widgetWithText(ListTile, label)
        : find.text(label);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
  }

  Future<void> mount(
    WidgetTester tester,
    ControlledRouting routing, {
    MunicipalBoundaryService? boundary,
    bool gpsOutside = false,
    GeocodingService? geocoding,
    PlaceSuggestionService? suggestions,
    void Function(RouteResult, String)? onStart,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchPanel(
            currentPosition: gpsOutside
                ? const LatLng(9, -72)
                : const LatLng(7.1, -73.1),
            locationStatus: LocationStatus.coordinatesObtained,
            boundaryService: boundary ?? rectangularBoundary(-74, 7, -73, 8),
            geocodingService: geocoding ?? FixedGeocoding(),
            placeSuggestionService: suggestions ?? FixedSuggestions(),
            routingService: routing,
            onStartNavigation: onStart,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('GPS fuera informa, evita OSRM y permite elegir otro origen', (
    tester,
  ) async {
    final routing = ControlledRouting();
    await mount(tester, routing, gpsOutside: true);
    expect(
      find.textContaining('Tu ubicación está fuera de la cobertura'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).last, 'Destino');
    await act(tester, 'Analizar rutas');
    expect(routing.calls, 0);
    expect(find.textContaining('El origen está fuera'), findsOneWidget);
    await tapLabel(tester, 'Cambiar');
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('destino geocodificado fuera nunca consulta OSRM', (
    tester,
  ) async {
    final routing = ControlledRouting();
    await mount(tester, routing, geocoding: OutsideGeocoding());
    await tester.enterText(find.byType(TextField).last, 'Lugar externo');
    await act(tester, 'Analizar rutas');
    expect(routing.calls, 0);
    expect(find.textContaining('El destino está fuera'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('sugerencia fuera mantiene etiqueta pero rechaza selección', (
    tester,
  ) async {
    final routing = ControlledRouting();
    await mount(tester, routing, suggestions: OutsideSuggestions());
    await tester.enterText(find.byType(TextField).last, 'Lugar externo');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fuera de la cobertura'), findsOneWidget);
    await act(tester, 'Lugar externo');
    expect(find.textContaining('El destino está fuera'), findsOneWidget);
    expect(routing.calls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'selección manual fuera deja mover mapa y confirmar un punto dentro',
    (tester) async {
      final routing = ControlledRouting();
      await mount(tester, routing);
      await tapLabel(tester, 'Elegir destino en el mapa');
      final options = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .options;
      options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(9, -72),
      );
      await tester.pump();
      expect(find.textContaining('El destino está fuera'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirmar ubicación'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).markers.single.point,
        const LatLng(9, -72),
      );
      options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(7.2, -73.2),
      );
      await tester.pump();
      await tapLabel(tester, 'Confirmar ubicación');
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        contains('Destino seleccionado en el mapa'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('desconocido no permite calcular; retry recupera planificación', (
    tester,
  ) async {
    var fail = true;
    final service = MunicipalBoundaryService(
      loader: () async {
        if (fail) throw StateError('asset ausente');
        return jsonEncode({
          'type': 'Polygon',
          'coordinates': [
            [
              [-74, 7],
              [-73, 7],
              [-73, 8],
              [-74, 8],
              [-74, 7],
            ],
          ],
        });
      },
    );
    final routing = ControlledRouting();
    await mount(tester, routing, boundary: service);
    expect(find.textContaining('Cobertura sin verificar'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Destino');
    await act(tester, 'Analizar rutas');
    expect(routing.calls, 0);
    expect(find.textContaining('No se pudo verificar'), findsOneWidget);
    fail = false;
    await tapLabel(tester, 'Reintentar cobertura');
    expect(service.available, isTrue);
    await act(tester, 'Analizar rutas');
    expect(
      routing.calls,
      1,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .join(' | '),
    );
    routing.pending.complete([
      const RouteResult(
        origin: LatLng(7.1, -73.1),
        destination: LatLng(7.2, -73.2),
        points: [LatLng(7.1, -73.1), LatLng(7.2, -73.2)],
        distanceMeters: 1000,
        durationSeconds: 100,
      ),
    ]);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'ruta con tramo exterior conserva extremos válidos y permite iniciar',
    (tester) async {
      final routing = ControlledRouting();
      var starts = 0;
      await mount(tester, routing, onStart: (_, _) => starts++);
      await tester.enterText(find.byType(TextField).last, 'Destino');
      await act(tester, 'Analizar rutas');
      expect(
        routing.calls,
        1,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      routing.pending.complete([
        const RouteResult(
          origin: LatLng(7.1, -73.1),
          destination: LatLng(7.2, -73.2),
          points: [LatLng(7.1, -73.1), LatLng(9, -72), LatLng(7.2, -73.2)],
          distanceMeters: 1000,
          durationSeconds: 100,
        ),
      ]);
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Iniciar navegación');
      expect(starts, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
