import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/screens/rutas/rutas_screen.dart';
import 'package:transporte_inteligente/services/municipal_boundary_service.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';

import '../../support/boundary_fixtures.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    MunicipalBoundaryService boundary,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: RutasScreen(
          loadRoutes: () async => [],
          boundaryService: boundary,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> point(WidgetTester tester, LatLng value) async {
    tester.widget<FlutterMap>(find.byType(FlutterMap)).options.onTap!(
      const TapPosition(Offset.zero, Offset.zero),
      value,
    );
    await tester.pump();
  }

  testWidgets('tap exterior en Rutas conserva ambos extremos anteriores', (
    tester,
  ) async {
    await mount(tester, rectangularBoundary(-74, 7, -73, 8));
    await point(tester, const LatLng(7.1, -73.1));
    await point(tester, const LatLng(7.2, -73.2));
    final before = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller!.text)
        .toList();
    await point(tester, const LatLng(9, -72));
    expect(find.textContaining('fuera de Bucaramanga'), findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.controller!.text)
          .toList(),
      before,
    );
    expect(
      tester
          .widget<RouteMap>(find.byType(RouteMap))
          .markers
          .map((marker) => marker.point),
      [const LatLng(7.1, -73.1), const LatLng(7.2, -73.2)],
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('tap con cobertura desconocida no añade marcador', (
    tester,
  ) async {
    await mount(
      tester,
      MunicipalBoundaryService(loader: () async => throw StateError('ausente')),
    );
    final before = tester
        .widget<RouteMap>(find.byType(RouteMap))
        .markers
        .map((marker) => marker.point)
        .toList();
    await point(tester, const LatLng(7.1, -73.1));
    expect(find.textContaining('No se pudo verificar'), findsOneWidget);
    expect(
      tester
          .widget<RouteMap>(find.byType(RouteMap))
          .markers
          .map((marker) => marker.point)
          .toList(),
      before,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
