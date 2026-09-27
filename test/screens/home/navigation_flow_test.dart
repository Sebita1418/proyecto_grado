import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/models/geocoding_result.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/widgets/navigation_status_card.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';
import 'package:transporte_inteligente/widgets/route_result_card.dart';
import 'package:transporte_inteligente/widgets/report_incident_sheet.dart';
import 'package:transporte_inteligente/widgets/road_incident_marker.dart';
import 'package:transporte_inteligente/widgets/road_incident_details_sheet.dart';

import '../../navigation/navigation_session_test.dart'
    show TrackingLocation, route;
import '../../reports/road_incident_test.dart' show FakeRoadIncidents;
import 'route_flow_test.dart'
    show ControlledRouting, FixedSuggestions, tapLabel;

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
      final routing = ControlledRouting();
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
      await tester.ensureVisible(find.text('Calcular ruta'));
      await tester.tap(find.text('Calcular ruta'));
      await tester.pump();
      routing.pending.complete([route]);
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Iniciar ruta');
      expect(find.byType(NavigationStatusCard), findsOneWidget);
      expect(find.byType(RouteResultCard), findsNothing);
      expect(find.text('Transporte Inteligente'), findsNothing);
      gps.position(const LatLng(0, .01));
      await tester.pumpAndSettle();
      var map = tester.widget<RouteMap>(find.byType(RouteMap));
      expect(map.polylines.length, 2);
      expect(map.polylines.first.points.last.longitude, closeTo(.01, 1e-10));
      expect(map.polylines.last.points.last, route.destination);
      expect(map.autoFit, isFalse);
      expect(find.textContaining('1.1 km restantes'), findsOneWidget);
      final session = tester
          .widget<NavigationStatusCard>(find.byType(NavigationStatusCard))
          .session;
      await tester.drag(find.byType(RouteMap), const Offset(60, 40));
      await tester.pumpAndSettle();
      expect(session.following, isFalse);
      await tester.tap(find.byTooltip('Recentrar'));
      await tester.pumpAndSettle();
      expect(session.following, isTrue);
      await tester.tap(find.byTooltip('Reportar novedad vial'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportIncidentSheet), findsOneWidget);
      await tester.tap(find.text('Accidente'));
      await tapLabel(tester, 'Publicar reporte');
      await tester.pumpAndSettle();
      expect(find.byType(NavigationStatusCard), findsOneWidget);
      await tester.tap(find.byType(RoadIncidentMarker));
      await tester.pumpAndSettle();
      expect(find.byType(RoadIncidentDetailsSheet), findsOneWidget);
      expect(find.text('Reporte publicado · Activo'), findsOneWidget);
      await tester.tap(find.byTooltip('Cerrar detalle'));
      await tester.pumpAndSettle();
      expect(session.isActive, isTrue);
      gps.position(route.destination);
      await tester.pumpAndSettle();
      expect(find.text('Has llegado a tu destino'), findsOneWidget);
      await tapLabel(tester, 'Finalizar ruta');
      expect(gps.updates.hasListener, isFalse);
      expect(find.byType(NavigationStatusCard), findsNothing);
      expect(find.byType(RouteResultCard), findsOneWidget);
      expect(routing.calls, 1);
      expect(incidents.creates, 1);
      expect(incidents.fetches, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(gps.updates.close);
      expect(incidents.events.hasListener, isFalse);
      await tester.runAsync(incidents.events.close);
    });
  }
}
