import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/models/perfil_model.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/services/mobility_preferences_service.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';
import 'package:transporte_inteligente/widgets/report_incident_sheet.dart';
import 'package:transporte_inteligente/widgets/report_location_picker.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';
import 'package:transporte_inteligente/widgets/route_result_card.dart';

import 'route_flow_test.dart'
    show
        ControlledRouting,
        FixedLocation,
        FixedGeocoding,
        FixedSuggestions,
        firstRoute,
        secondRoute,
        tapLabel;

class DeniedLocation extends LocationService {
  @override
  Future<LocationResult> locate() async =>
      const LocationResult(LocationStatus.permissionDenied);
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      MobilityPreferencesService.storageKey: ['driving'],
    }),
  );

  Future<void> home(
    WidgetTester tester,
    ControlledRouting routing, {
    double width = 390,
    bool denied = false,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: HomeScreen(
          locationService: denied ? DeniedLocation() : FixedLocation(),
          loadProfile: () async => Perfil(
            id: 'test',
            nombre: 'Ana',
            correo: 'ana@example.test',
            rol: 'usuario',
            activo: true,
          ),
          routingService: routing,
          geocodingService: FixedGeocoding(),
          placeSuggestionService: FixedSuggestions(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> point(WidgetTester tester, LatLng coordinates) async {
    tester.widget<FlutterMap>(find.byType(FlutterMap)).options.onTap!(
      const TapPosition(Offset.zero, Offset.zero),
      coordinates,
    );
    await tester.pump();
  }

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'reporte conserva ruta, borrador y preferencias a $width / texto 150%',
      (tester) async {
        final routing = ControlledRouting();
        addTearDown(routing.dispose);
        await home(tester, routing, width: width);
        expect(
          tester.getSize(find.byType(MapSearchPanel)).height,
          lessThan(844 * .5),
        );
        await tester.enterText(find.byType(TextField).last, 'Destino');
        await tester.ensureVisible(find.text('Calcular ruta'));
        await tester.tap(find.text('Calcular ruta'));
        await tester.pump();
        routing.pending.complete([firstRoute, secondRoute]);
        await tester.pumpAndSettle();
        expect(
          tester.widget<RouteResultCard>(find.byType(RouteResultCard)).fastest,
          isTrue,
        );
        await tester.ensureVisible(find.byTooltip('Alternativa anterior'));
        await tester.tap(find.byTooltip('Alternativa anterior'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<RouteResultCard>(find.byType(RouteResultCard)).shortest,
          isTrue,
        );
        expect(find.text('Selección manual'), findsOneWidget);
        await tester.tap(find.byTooltip('Capas del mapa'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(CheckedPopupMenuItem<String>, 'Ruta calculada'),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<RouteMap>(find.byType(RouteMap)).polylines,
          isEmpty,
        );
        await tester.tap(find.byTooltip('Ver ruta completa'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<RouteMap>(find.byType(RouteMap))
              .polylines
              .single
              .points,
          firstRoute.points,
        );

        await tester.tap(find.byTooltip('Reportar novedad vial'));
        await tester.pumpAndSettle();
        await tapLabel(tester, 'Obra en la vía');
        await tester.enterText(find.byType(TextField), 'Borrador de prueba');
        await tapLabel(tester, 'Cambiar ubicación');
        expect(find.byType(ReportLocationPicker), findsOneWidget);
        expect(
          tester
              .widget<RouteMap>(find.byType(RouteMap))
              .polylines
              .single
              .points,
          firstRoute.points,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirmar ubicación'),
              )
              .onPressed,
          isNull,
        );
        const selected = LatLng(7.10123, -73.10123);
        await point(tester, const LatLng(7.1001, -73.1001));
        await point(tester, selected);
        final semantics = tester.ensureSemantics();
        await tester.pump();
        expect(
          find.bySemanticsLabel('Ubicación del borrador de novedad'),
          findsOneWidget,
        );
        semantics.dispose();
        await tapLabel(tester, 'Confirmar ubicación');
        expect(find.text('Ubicación elegida en el mapa'), findsOneWidget);
        expect(find.text('7.10123, -73.10123'), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Borrador de prueba',
        );

        await tapLabel(tester, 'Cambiar ubicación');
        await point(tester, const LatLng(8, -72));
        await tapLabel(tester, 'Cancelar');
        expect(find.text('7.10123, -73.10123'), findsOneWidget);
        await tapLabel(tester, 'Preparar reporte');
        expect(find.byType(ReportIncidentSheet), findsNothing);
        expect(
          find.textContaining('Envío de reportes pendiente'),
          findsOneWidget,
        );
        expect(
          tester.widget<RouteResultCard>(find.byType(RouteResultCard)).route,
          same(firstRoute),
        );
        expect(
          tester
              .widget<RouteMap>(find.byType(RouteMap))
              .polylines
              .single
              .points,
          firstRoute.points,
        );
        expect(routing.calls, 1);
        expect(
          (await SharedPreferences.getInstance()).getStringList(
            MobilityPreferencesService.storageKey,
          ),
          ['driving'],
        );

        await tester.tap(find.byTooltip('Reportar novedad vial'));
        await tester.pumpAndSettle();
        expect(find.text('7.10123, -73.10123'), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Borrador de prueba',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'sin GPS no prepara sin coordenadas; cancelar y volver no inventa ubicación',
    (tester) async {
      final routing = ControlledRouting();
      addTearDown(routing.dispose);
      await home(tester, routing, denied: true);
      await tester.tap(find.byTooltip('Reportar novedad vial'));
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Otro');
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Preparar reporte'),
            )
            .onPressed,
        isNull,
      );
      await tapLabel(tester, 'Cambiar ubicación');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Ubicación no disponible'), findsOneWidget);
      await tapLabel(tester, 'Cambiar ubicación');
      await tester.tapAt(
        tester.getTopLeft(find.byType(FlutterMap)) + const Offset(120, 120),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirmar ubicación'),
            )
            .onPressed,
        isNotNull,
      );
      await tapLabel(tester, 'Confirmar ubicación');
      expect(find.text('Ubicación elegida en el mapa'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Preparar reporte'),
            )
            .onPressed,
        isNotNull,
      );
      expect(routing.calls, 0);
    },
  );

  testWidgets(
    'capas reales no recalculan; drawer identifica mapa y perfil real',
    (tester) async {
      final routing = ControlledRouting();
      addTearDown(routing.dispose);
      await home(tester, routing);
      expect(find.text('A'), findsOneWidget);
      await tester.tap(find.byTooltip('Capas del mapa'));
      await tester.pumpAndSettle();
      expect(find.text('Mapa base: OpenStreetMap'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(
          CheckedPopupMenuItem<String>,
          'Marcador de mi ubicación',
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<RouteMap>(find.byType(RouteMap)).markers, isEmpty);
      await tester.tap(find.byTooltip('Mi ubicación'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).markers,
        hasLength(1),
      );
      await tester.tap(find.byTooltip('Abrir menú de navegación'));
      await tester.pumpAndSettle();
      expect(find.text('Ana'), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Mapa / Inicio'))
            .selected,
        isTrue,
      );
      expect(routing.calls, 0);
    },
  );
}
