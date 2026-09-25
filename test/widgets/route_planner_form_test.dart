import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transporte_inteligente/widgets/route_planner_form.dart';

void main() {
  testWidgets(
    'etiquetas de Rutas conservan callback y bloqueo durante localización',
    (tester) async {
      final origin = TextEditingController();
      final destination = TextEditingController();
      addTearDown(origin.dispose);
      addTearDown(destination.dispose);
      var calls = 0;
      Future<void> render(bool loading) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePlannerForm(
              originController: origin,
              destinationController: destination,
              onCalculate: () => calls++,
              actionLabel: 'Mostrar puntos',
              loadingLabel: 'Localizando…',
              isLoading: loading,
            ),
          ),
        ),
      );
      await render(false);
      expect(find.text('Calcular ruta'), findsNothing);
      await tester.tap(find.text('Mostrar puntos'));
      expect(calls, 1);
      await render(true);
      expect(find.text('Localizando…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).first).enabled,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

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
