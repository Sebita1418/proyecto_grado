import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transporte_inteligente/widgets/route_planner_form.dart';

void main() {
  testWidgets('muestra los campos de origen y destino', (
    WidgetTester tester,
  ) async {
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

    expect(find.text('Origen'), findsOneWidget);
    expect(find.text('Destino'), findsOneWidget);
    expect(find.text('Calcular ruta'), findsOneWidget);

    originController.dispose();
    destinationController.dispose();
  });

  testWidgets('ejecuta onCalculate al presionar el botón', (
    WidgetTester tester,
  ) async {
    final originController = TextEditingController();
    final destinationController = TextEditingController();

    var llamado = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutePlannerForm(
            originController: originController,
            destinationController: destinationController,
            onCalculate: () {
              llamado = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Calcular ruta'));
    await tester.pump();

    expect(llamado, isTrue);

    originController.dispose();
    destinationController.dispose();
  });

  testWidgets('muestra errores de origen y destino', (
    WidgetTester tester,
  ) async {
    final originController = TextEditingController();
    final destinationController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutePlannerForm(
            originController: originController,
            destinationController: destinationController,
            onCalculate: () {},
            originError: 'Ingresa el punto de origen.',
            destinationError: 'Ingresa el punto de destino.',
          ),
        ),
      ),
    );

    expect(find.text('Ingresa el punto de origen.'), findsOneWidget);

    expect(find.text('Ingresa el punto de destino.'), findsOneWidget);

    originController.dispose();
    destinationController.dispose();
  });

  testWidgets('muestra estado de carga mientras calcula la ruta', (
    WidgetTester tester,
  ) async {
    final originController = TextEditingController();
    final destinationController = TextEditingController();

    var llamado = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutePlannerForm(
            originController: originController,
            destinationController: destinationController,
            onCalculate: () {
              llamado = true;
            },
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.text('Calculando...'), findsOneWidget);
    expect(find.text('Calcular ruta'), findsNothing);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(button.onPressed, isNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(llamado, isFalse);

    originController.dispose();
    destinationController.dispose();
  });
}
