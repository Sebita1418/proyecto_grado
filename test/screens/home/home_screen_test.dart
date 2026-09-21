import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/screens/nearby/nearby_places_screen.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';

class FakeLocationService extends LocationService {
  FakeLocationService(this.result);
  final LocationResult result;
  @override
  Future<LocationResult> locate() async => result;
}

void main() {
  Future<void> render(WidgetTester tester, LocationResult result) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          locationService: FakeLocationService(result),
          loadProfile: () async => null,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Home muestra OSM, ubicación y navegación', (tester) async {
    await render(
      tester,
      const LocationResult(
        LocationStatus.coordinatesObtained,
        coordinates: LatLng(7.1, -73.1),
      ),
    );
    expect(find.byType(RouteMap), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byTooltip('Mi ubicación'), findsWidgets);
    expect(find.text('Hola,'), findsNothing);
    expect(find.text('¿Qué deseas consultar?'), findsNothing);
    expect(find.byTooltip('Mi ubicación'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pump();
    expect(find.text('Muévete mejor. Decide tu ruta.'), findsNWidgets(2));
    expect(find.text('Mapa / Inicio'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(
            find.ancestor(
              of: find.text('Mapa / Inicio'),
              matching: find.byType(ListTile),
            ),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Rutas'), findsOneWidget);
    expect(find.text('Puntos cercanos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('sin permiso conserva mapa y origen manual', (tester) async {
    await render(tester, const LocationResult(LocationStatus.permissionDenied));
    expect(find.byType(RouteMap), findsOneWidget);
    expect(find.text('Origen'), findsOneWidget);
    expect(find.byTooltip('Mi ubicación'), findsOneWidget);
  });

  testWidgets('perfil sin datos informa y permite reintentar', (tester) async {
    await render(tester, const LocationResult(LocationStatus.permissionDenied));
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tu perfil no está disponible. Intenta cargarlo de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(RouteMap), findsOneWidget);
  });

  testWidgets('Puntos cercanos abre la pantalla y permite volver al mapa', (
    tester,
  ) async {
    await render(
      tester,
      const LocationResult(
        LocationStatus.coordinatesObtained,
        coordinates: LatLng(7.1, -73.1),
      ),
    );
    for (final useBackButton in [false, true]) {
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Puntos cercanos'));
      await tester.pumpAndSettle();
      expect(find.byType(NearbyPlacesScreen), findsOneWidget);
      expect(find.text('Aún no disponible'), findsOneWidget);
      if (useBackButton) {
        await tester.tap(find.byType(BackButton));
      } else {
        await tester.ensureVisible(find.text('Volver al mapa'));
        await tester.tap(find.text('Volver al mapa'));
      }
      await tester.pumpAndSettle();
      expect(find.byType(NearbyPlacesScreen), findsNothing);
      expect(find.byType(RouteMap), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
    }
  });
}
