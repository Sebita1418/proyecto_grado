import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/models/geocoding_result.dart';
import 'package:transporte_inteligente/models/place_suggestion.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/models/perfil_model.dart';
import 'package:transporte_inteligente/services/geocoding_service.dart';
import 'package:transporte_inteligente/services/place_suggestion_service.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/services/municipal_boundary_service.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';
import 'package:transporte_inteligente/widgets/report_incident_sheet.dart';

import '../../support/operational_coverage_fixtures.dart';
import '../../reports/road_incident_test.dart' show FakeRoadIncidents;
import 'route_flow_test.dart' show ControlledRouting, tapLabel;

class ReferenceGeocoding extends GeocodingService {
  ReferenceGeocoding(this.point);
  final LatLng point;
  @override
  Future<GeocodingResult?> search(String query) async => GeocodingResult(
    latitude: point.latitude,
    longitude: point.longitude,
    displayName: query,
  );
}

class ReferenceSuggestions extends PlaceSuggestionService {
  ReferenceSuggestions(this.points);
  final Map<String, LatLng> points;
  @override
  Future<List<PlaceSuggestion>> search(String query) async {
    final name = query.startsWith('Origen') ? 'Girón' : 'Parque Santander';
    final point = points[name]!;
    return [
      PlaceSuggestion(
        name: name,
        description: 'Referencia verificada',
        latitude: point.latitude,
        longitude: point.longitude,
      ),
    ];
  }
}

class ReferenceLocation extends LocationService {
  ReferenceLocation(this.point);
  final LatLng point;
  @override
  Future<LocationResult> locate() async =>
      LocationResult(LocationStatus.coordinatesObtained, coordinates: point);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, LatLng> points;
  late MunicipalBoundaryService boundary;
  setUpAll(() async {
    points = await operationalReferencePoints();
    boundary = MunicipalBoundaryService();
    await boundary.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> analyze(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Analizar rutas'));
    await tester.tap(find.text('Analizar rutas'));
    await tester.pump();
  }

  for (final destination in ['Parque Santander', 'Floridablanca']) {
    testWidgets('GPS Girón permite planificar hacia $destination', (
      tester,
    ) async {
      final routing = ControlledRouting();
      final origin = points['Girón']!, target = points[destination]!;
      var starts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapSearchPanel(
              currentPosition: origin,
              locationStatus: LocationStatus.coordinatesObtained,
              boundaryService: boundary,
              geocodingService: ReferenceGeocoding(target),
              placeSuggestionService: ReferenceSuggestions(points),
              routingService: routing,
              onStartNavigation: (_, _) => starts++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Tu ubicación está fuera'), findsNothing);
      await tester.enterText(find.byType(TextField).last, destination);
      await analyze(tester);
      expect(routing.lastOrigin, origin);
      expect(routing.lastDestination, target);
      // An external intermediate point must not invalidate legal endpoints.
      routing.pending.complete([
        RouteResult(
          origin: origin,
          destination: target,
          points: [origin, points['Piedecuesta']!, target],
          distanceMeters: 10000,
          durationSeconds: 600,
        ),
      ]);
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Iniciar navegación');
      expect(starts, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'origen manual Girón y destino Bucaramanga usan coordenadas seleccionadas',
    (tester) async {
      final routing = ControlledRouting();
      LatLng? selectedOrigin, selectedDestination;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapSearchPanel(
              currentPosition: null,
              locationStatus: LocationStatus.permissionDenied,
              boundaryService: boundary,
              placeSuggestionService: ReferenceSuggestions(points),
              routingService: routing,
              onOriginSelected: (p) => selectedOrigin = p,
              onDestinationSelected: (p) => selectedDestination = p,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final origin in [true, false]) {
        await tester.enterText(
          origin ? find.byType(TextField).first : find.byType(TextField).last,
          origin ? 'Origen' : 'Destino',
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        final tile = find.widgetWithText(
          ListTile,
          origin ? 'Girón' : 'Parque Santander',
        );
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
      }
      expect(selectedOrigin, points['Girón']);
      expect(selectedDestination, points['Parque Santander']);
      await analyze(tester);
      expect(routing.lastOrigin, points['Girón']);
      expect(routing.lastDestination, points['Parque Santander']);
      routing.pending.complete([
        RouteResult(
          origin: selectedOrigin!,
          destination: selectedDestination!,
          points: [selectedOrigin!, selectedDestination!],
          distanceMeters: 10000,
          durationSeconds: 600,
        ),
      ]);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('mapa y publicación de reportes conservan GPS Girón', (
    tester,
  ) async {
    final incidents = FakeRoadIncidents();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          initiallyCollapsed: false,
          boundaryService: boundary,
          locationService: ReferenceLocation(points['Girón']!),
          roadIncidentService: incidents,
          loadProfile: () async => Perfil(
            id: 'test',
            nombre: 'Ana',
            correo: 'ana@example.test',
            rol: 'usuario',
            activo: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<RouteMap>(find.byType(RouteMap)).boundaryPolygons,
      hasLength(3),
    );
    await tester.ensureVisible(find.byTooltip('Reportar novedad vial'));
    await tester.tap(find.byTooltip('Reportar novedad vial'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ReportIncidentSheet>(find.byType(ReportIncidentSheet))
          .currentPosition,
      points['Girón'],
    );
    await tapLabel(tester, 'Obra en la vía');
    await tapLabel(tester, 'Enviar reporte');
    expect(incidents.creates, 1);
    expect(incidents.rows.single.coordinates, points['Girón']);
    expect(
      tester
          .widget<RouteMap>(find.byType(RouteMap))
          .overlayMarkers
          .any((m) => m.point == points['Girón']),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(incidents.events.close);
  });
}
