import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transporte_inteligente/widgets/route_summary_card.dart';

void main() {
  testWidgets('muestra correctamente el resumen de una ruta', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RouteSummaryCard(
            origin: 'Parque Principal',
            destination: 'Universidad',
            distance: '8.5 km',
            duration: '18 min',
          ),
        ),
      ),
    );

    expect(find.text('Resumen de la ruta'), findsOneWidget);

    expect(find.text('Origen'), findsOneWidget);
    expect(find.text('Parque Principal'), findsOneWidget);

    expect(find.text('Destino'), findsOneWidget);
    expect(find.text('Universidad'), findsOneWidget);

    expect(find.text('Distancia'), findsOneWidget);
    expect(find.text('8.5 km'), findsOneWidget);

    expect(find.text('18 min'), findsOneWidget);

    expect(find.byIcon(Icons.route_outlined), findsOneWidget);
    expect(find.byIcon(Icons.trip_origin), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    expect(find.byIcon(Icons.straighten), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });

  testWidgets('muestra los valores recibidos por el componente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RouteSummaryCard(
            origin: 'Floridablanca',
            destination: 'Bucaramanga',
            distance: '12 km',
            duration: '25 min',
          ),
        ),
      ),
    );

    expect(find.text('Floridablanca'), findsOneWidget);
    expect(find.text('Bucaramanga'), findsOneWidget);
    expect(find.text('12 km'), findsOneWidget);
    expect(find.text('25 min'), findsOneWidget);
  });
}
