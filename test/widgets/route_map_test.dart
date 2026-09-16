import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';

void main() {
  const initialPosition = LatLng(7.119349, -73.122742);

  testWidgets('transmite el tap OSM y acepta polylines opcionales', (
    tester,
  ) async {
    LatLng? selected;
    const destination = LatLng(7.14, -73.11);
    final line = Polyline(points: [initialPosition, destination]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteMap(
            initialPosition: initialPosition,
            polylines: [line],
            onTap: (point) => selected = point,
          ),
        ),
      ),
    );
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    map.options.onTap!(
      const TapPosition(Offset.zero, Offset.zero),
      destination,
    );
    expect(selected, destination);
    expect(tester.widget<PolylineLayer>(find.byType(PolylineLayer)).polylines, [
      line,
    ]);
  });

  testWidgets('RouteMap renderiza el mapa con OpenStreetMap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RouteMap(initialPosition: initialPosition)),
      ),
    );

    await tester.pump();

    expect(find.byType(RouteMap), findsOneWidget);

    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('RouteMap expone la semántica del mapa', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RouteMap(initialPosition: initialPosition)),
      ),
    );

    await tester.pump();

    expect(find.bySemanticsLabel('Mapa de consulta de ruta'), findsOneWidget);
  });

  testWidgets('sin marcadores conserva el centro y zoom iniciales', (
    WidgetTester tester,
  ) async {
    final controller = MapController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteMap(
            initialPosition: initialPosition,
            mapController: controller,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(controller.camera.center, initialPosition);
    expect(controller.camera.zoom, 14);
  });

  testWidgets('ajusta la cámara en búsquedas sucesivas', (
    WidgetTester tester,
  ) async {
    final controller = MapController();
    const origin = LatLng(7.1255, -73.1198);
    const destination = LatLng(7.0872, -73.1052);
    const secondOrigin = LatLng(7.1400, -73.1500);
    const secondDestination = LatLng(7.0100, -73.0300);

    Widget buildMap(List<Marker> markers) {
      return MaterialApp(
        home: Scaffold(
          body: RouteMap(
            initialPosition: initialPosition,
            markers: markers,
            mapController: controller,
          ),
        ),
      );
    }

    await tester.pumpWidget(
      buildMap(const [
        Marker(point: initialPosition, child: Icon(Icons.location_on)),
      ]),
    );
    await tester.pump();
    expect(controller.camera.center, initialPosition);

    await tester.pumpWidget(
      buildMap(const [
        Marker(point: origin, child: Icon(Icons.trip_origin)),
        Marker(point: destination, child: Icon(Icons.location_on)),
      ]),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(controller.camera.visibleBounds.contains(origin), isTrue);
    expect(controller.camera.visibleBounds.contains(destination), isTrue);
    final firstSearchCenter = controller.camera.center;

    await tester.pumpWidget(
      buildMap(const [
        Marker(point: secondOrigin, child: Icon(Icons.trip_origin)),
        Marker(point: secondDestination, child: Icon(Icons.location_on)),
      ]),
    );
    await tester.pump();
    await tester.pump();

    expect(controller.camera.visibleBounds.contains(secondOrigin), isTrue);
    expect(controller.camera.visibleBounds.contains(secondDestination), isTrue);
    expect(controller.camera.center, isNot(firstSearchCenter));
  });
}
