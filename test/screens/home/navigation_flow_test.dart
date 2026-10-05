import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/models/geocoding_result.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/models/road_incident_report.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/widgets/navigation_status_card.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';
import 'package:transporte_inteligente/widgets/route_result_card.dart';
import 'package:transporte_inteligente/widgets/report_incident_sheet.dart';
import 'package:transporte_inteligente/widgets/road_incident_marker.dart';
import 'package:transporte_inteligente/widgets/road_incident_details_sheet.dart';

import '../../navigation/navigation_session_test.dart' show TrackingLocation;
import '../../navigation/navigation_v2_test.dart' show v2Route;
import '../../reports/road_incident_test.dart'
    show FakeRoadIncidents, reportRow;
import 'route_flow_test.dart'
    show ControlledRouting, FixedSuggestions, tapLabel;

const route = v2Route;

class NavigationRouting extends ControlledRouting {
  int reroutes = 0;
  final recalculation = Completer<RouteResult>();
  @override
  Future<RouteResult> route({
    required LatLng origin,
    required LatLng destination,
  }) {
    reroutes++;
    expect(origin, const LatLng(.002, .01));
    expect(destination, v2Route.destination);
    return recalculation.future;
  }
}

class NavigationGeocoding extends GeocodingService {
  @override
  Future<GeocodingResult?> search(String query) async => const GeocodingResult(
    latitude: 0,
    longitude: .02,
    displayName: 'Destino',
  );
}

void main() {
  for (final size in [
    const Size(320, 844),
    const Size(390, 844),
    const Size(768, 844),
    const Size(1440, 844),
    const Size(390, 420),
  ]) {
    testWidgets('navegación GPS y retorno al resultado a $size', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gps = TrackingLocation();
      final incidents = FakeRoadIncidents();
      final routing = NavigationRouting();
      addTearDown(routing.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            roadIncidentService: incidents,
            locationService: gps,
            loadProfile: () async => null,
            routingService: routing,
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
      routing.pending.complete([route]);
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Iniciar navegación');
      expect(find.byType(NavigationStatusCard), findsOneWidget);
      expect(find.byType(RouteResultCard), findsNothing);
      expect(find.text('Transporte Inteligente'), findsNothing);
      expect(
        tester
            .getRect(find.byType(NavigationManeuverCard))
            .overlaps(tester.getRect(find.byTooltip('Reportar novedad vial'))),
        isFalse,
      );
      gps.position(const LatLng(0, .01));
      await tester.pumpAndSettle();
      var map = tester.widget<RouteMap>(find.byType(RouteMap));
      expect(map.polylines.length, 2);
      expect(map.polylines.first.points.last.longitude, closeTo(.01, 1e-10));
      expect(map.polylines.last.points.last, route.destination);
      expect(map.autoFit, isFalse);
      expect(find.textContaining('1.1 km restantes'), findsOneWidget);
      expect(find.text('Gira a la derecha en Carrera 27'), findsOneWidget);
      final session = tester
          .widget<NavigationStatusCard>(find.byType(NavigationStatusCard))
          .session;
      await tester.drag(find.byType(RouteMap), const Offset(60, 40));
      await tester.pumpAndSettle();
      expect(session.following, isFalse);
      expect(find.text('Volver a seguir mi ubicación'), findsOneWidget);
      await tester.tap(find.byTooltip('Minimizar navegación'));
      await tester.pumpAndSettle();
      expect(find.text('Finalizar ruta'), findsOneWidget);
      expect(session.isActive, isTrue);
      await tester.tap(find.byTooltip('Expandir navegación'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Abrir menú de navegación'));
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Mapa / Inicio');
      expect(session.isActive, isTrue);
      expect(routing.calls, 1);
      await tester.tap(find.byTooltip('Recentrar mapa'));
      await tester.pumpAndSettle();
      expect(session.following, isTrue);
      await tester.tap(find.byTooltip('Reportar novedad vial'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportIncidentSheet), findsOneWidget);
      await tester.tap(find.text('Accidente'));
      await tapLabel(tester, 'Enviar reporte');
      await tester.pumpAndSettle();
      expect(find.byType(NavigationStatusCard), findsOneWidget);
      await tester.tap(find.byType(RoadIncidentMarker));
      await tester.pumpAndSettle();
      expect(find.byType(RoadIncidentDetailsSheet), findsOneWidget);
      expect(find.text('Reporte publicado · Activo'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar detalle'));
      await tester.pumpAndSettle();
      expect(session.isActive, isTrue);
      await tester.tap(find.byTooltip('Reportes de la vía'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Accidente'));
      await tester.pumpAndSettle();
      expect(find.byType(RoadIncidentDetailsSheet), findsOneWidget);
      expect(session.isActive, isTrue);
      expect(session.following, isFalse);
      expect(session.route, same(route));
      expect(routing.calls, 1);
      await tester.tap(find.byTooltip('Cerrar detalle'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Recentrar mapa'));
      await tester.pumpAndSettle();
      expect(session.following, isTrue);
      gps.position(const LatLng(.002, .01));
      gps.position(const LatLng(.002, .01));
      gps.position(const LatLng(.002, .01));
      await tester.pumpAndSettle();
      expect(find.text('Recalculando ruta…'), findsOneWidget);
      incidents.rows.add(
        RoadIncidentReport.fromMap({
          ...reportRow(id: 'remote-report'),
          'latitud': .002,
          'longitud': .01,
        }),
      );
      incidents.events.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 351));
      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).overlayMarkers.length,
        2,
      );
      const updated = RouteResult(
        origin: LatLng(.002, .01),
        destination: LatLng(0, .02),
        points: [LatLng(.002, .01), LatLng(0, .015), LatLng(0, .02)],
        distanceMeters: 1300,
        durationSeconds: 350,
      );
      routing.recalculation.complete(updated);
      await tester.pumpAndSettle();
      expect(session.route, same(updated));
      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).polylines.last.points,
        orderedEquals(updated.points),
      );
      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).overlayMarkers.length,
        2,
      );
      expect(find.text('Ruta actualizada'), findsOneWidget);
      gps.position(route.destination);
      await tester.pumpAndSettle();
      expect(find.text('Has llegado a tu destino'), findsOneWidget);
      await tapLabel(tester, 'Finalizar ruta');
      expect(gps.updates.hasListener, isFalse);
      expect(find.byType(NavigationStatusCard), findsNothing);
      expect(find.byType(RouteResultCard), findsOneWidget);
      expect(routing.calls, 1);
      expect(routing.reroutes, 1);
      expect(incidents.creates, 1);
      expect(incidents.fetches, 2); // carga inicial + evento; nunca por GPS
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(gps.updates.close);
      expect(incidents.events.hasListener, isFalse);
      await tester.runAsync(incidents.events.close);
    });
  }
}
