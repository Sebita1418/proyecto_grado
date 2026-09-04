import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';

void main() {
  testWidgets('RouteMap crea el contenedor visual del mapa', (
    WidgetTester tester,
  ) async {
    const initialPosition = LatLng(4.7110, -74.0721);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RouteMap(initialPosition: initialPosition)),
      ),
    );

    expect(find.bySemanticsLabel('Mapa de consulta de ruta'), findsOneWidget);

    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
