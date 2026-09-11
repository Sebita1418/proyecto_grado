import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/widgets/route_planner_form.dart';

void main() {
  testWidgets('muestra los campos de origen y destino', (tester) async {
    final originController = TextEditingController();
    final destinationController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutePlannerForm(
            originController: originController,
            destinationController: destinationController,
            onCalculate: () {},
          ),
        ),
      ),
    );

    expect(find.text('Planifica tu ruta'), findsOneWidget);
    expect(find.text('Origen'), findsOneWidget);
    expect(find.text('Destino'), findsOneWidget);
    expect(find.text('Calcular ruta'), findsOneWidget);

    originController.dispose();
    destinationController.dispose();
  });

  testWidgets('ejecuta onCalculate al presionar el botón', (tester) async {
    final originController = TextEditingController();
    final destinationController = TextEditingController();
    var calculateCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutePlannerForm(
            originController: originController,
            destinationController: destinationController,
            onCalculate: () {
              calculateCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Calcular ruta'));
    await tester.pump();

    expect(calculateCalled, isTrue);

    originController.dispose();
    destinationController.dispose();
  });
}
