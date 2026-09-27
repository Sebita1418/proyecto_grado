import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/services/mobility_preferences_service.dart';
import 'package:transporte_inteligente/widgets/navigation_header.dart';
import 'package:transporte_inteligente/widgets/map_floating_controls.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';
import 'package:transporte_inteligente/widgets/report_incident_sheet.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';
import 'package:transporte_inteligente/widgets/road_incident_marker.dart';
import 'package:transporte_inteligente/widgets/road_incident_details_sheet.dart';
import 'package:transporte_inteligente/widgets/travel_mode_selector.dart';

class TestLocationService extends LocationService {
  @override
  Future<LocationResult> locate() async => const LocationResult(
    LocationStatus.coordinatesObtained,
    coordinates: LatLng(7.1193, -73.1227),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    double width = 390,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: HomeScreen(
          locationService: TestLocationService(),
          loadProfile: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'teclado conserva controles separados y planner dentro del viewport',
    (tester) async {
      await pumpHome(tester, width: 320, textScale: 1.5);
      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final controls = tester.getRect(find.byType(MapFloatingControls));
      final report = tester.getRect(find.byTooltip('Reportar novedad vial'));
      final panel = tester.getRect(find.byType(MapSearchPanel));
      expect(controls.overlaps(report), isFalse);
      expect(controls.overlaps(panel), isFalse);
      expect(report.overlaps(panel), isFalse);
      expect(panel.bottom, lessThanOrEqualTo(444));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Map Experience V2 muestra NavigationHeader flotante y mapa full-screen',
    (tester) async {
      await pumpHome(tester);

      expect(find.byType(NavigationHeader), findsOneWidget);
      expect(find.byType(RouteMap), findsOneWidget);
      expect(find.text('Transporte Inteligente'), findsOneWidget);
      expect(find.text('Muévete mejor. Decide tu ruta.'), findsOneWidget);

      // Verify floating controls
      expect(find.byTooltip('Mi ubicación'), findsWidgets);
      expect(find.byTooltip('Reportar novedad vial'), findsOneWidget);
      expect(find.text('Reportar'), findsOneWidget);

      // Verify mode selector in search panel
      expect(find.byType(TravelModeSelector), findsOneWidget);
      expect(find.text('Vehículo'), findsOneWidget);
      expect(find.textContaining('Próximamente'), findsNWidgets(3));
    },
  );

  testWidgets('menú del NavigationHeader abre Drawer con Reportes de la vía', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('Abrir menú de navegación'));
    await tester.pumpAndSettle();

    expect(find.text('Mapa / Inicio'), findsOneWidget);
    expect(find.text('Rutas'), findsOneWidget);
    expect(find.text('Reportes de la vía'), findsOneWidget);
    expect(find.text('Puntos cercanos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);

    // Tapping Reportes de la vía closes drawer and opens ReportIncidentSheet
    await tester.tap(find.text('Reportes de la vía'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportIncidentSheet), findsOneWidget);
    expect(find.text('Reportar novedad'), findsOneWidget);

    // Close sheet
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportIncidentSheet), findsNothing);
  });

  testWidgets(
    'botón flotante Reportar abre ReportIncidentSheet y envía draft honesto',
    (tester) async {
      await pumpHome(tester);

      // Tap floating Reportar button
      await tester.tap(find.byTooltip('Reportar novedad vial'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportIncidentSheet), findsOneWidget);

      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).overlayMarkers,
        isEmpty,
      );

      // Select 'Congestión'
      await tester.tap(find.text('Congestión'));
      await tester.pump();

      // Submit report
      await tester.ensureVisible(find.text('Preparar reporte'));
      await tester.tap(find.text('Preparar reporte'));
      await tester.pumpAndSettle();

      // Verify sheet is closed and honest feedback is displayed without fake persistence
      expect(find.byType(ReportIncidentSheet), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      final map = tester.widget<RouteMap>(find.byType(RouteMap));
      expect(map.overlayMarkers.single.point, const LatLng(7.1193, -73.1227));
      expect(find.byType(RoadIncidentMarker), findsOneWidget);
      await tester.tap(find.byType(RoadIncidentMarker));
      await tester.pumpAndSettle();
      expect(find.byType(RoadIncidentDetailsSheet), findsOneWidget);
      expect(find.text('Borrador sin publicar'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar detalle'));
      await tester.pumpAndSettle();
      expect(find.byType(RoadIncidentDetailsSheet), findsNothing);
      expect(
        find.textContaining('Borrador preparado. Envío de reportes'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'elección de modo en viaje no sobreescribe preferencias persistidas en SharedPreferences',
    (tester) async {
      final preferencesService = const MobilityPreferencesService();
      await preferencesService.save({
        TransportMode.cycling,
        TransportMode.walking,
      });

      final initialSaved = await preferencesService.load();
      expect(initialSaved, {TransportMode.cycling, TransportMode.walking});

      await pumpHome(tester);

      // In Home, the temporary mode selector shows Vehículo
      expect(find.byType(TravelModeSelector), findsOneWidget);

      // Tap Vehículo in selector
      await tester.tap(find.text('Vehículo'));
      await tester.pumpAndSettle();

      // Verify SharedPreferences were NOT modified or overwritten with driving
      final postCheckSaved = await preferencesService.load();
      expect(postCheckSaved, {TransportMode.cycling, TransportMode.walking});
      expect(postCheckSaved.contains(TransportMode.driving), isFalse);
    },
  );

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'Home Map Experience V2 se adapta sin overflow a ${width.toInt()} px con texto 1.5x',
      (tester) async {
        await pumpHome(tester, width: width, textScale: 1.5);

        expect(tester.takeException(), isNull);
        expect(find.byType(NavigationHeader), findsOneWidget);
        expect(find.byType(RouteMap), findsOneWidget);
        expect(find.byType(TravelModeSelector), findsOneWidget);
        expect(find.byTooltip('Reportar novedad vial'), findsOneWidget);
      },
    );
  }
}
