import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
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
    expect(find.byTooltip('Centrar en mi ubicación'), findsOneWidget);
    expect(find.text('Hola,'), findsNothing);
    expect(find.text('¿Qué deseas consultar?'), findsNothing);
    expect(find.byTooltip('Mi ubicación'), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pump();
    expect(find.text('Mapa / Inicio'), findsOneWidget);
    expect(find.text('Rutas'), findsOneWidget);
    expect(find.text('Puntos cercanos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('sin permiso conserva mapa y origen manual', (tester) async {
    await render(tester, const LocationResult(LocationStatus.permissionDenied));
    expect(find.byType(RouteMap), findsOneWidget);
    expect(find.text('Origen'), findsOneWidget);
    expect(find.byTooltip('Centrar en mi ubicación'), findsOneWidget);
  });
}
