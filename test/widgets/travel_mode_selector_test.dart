import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/widgets/travel_mode_selector.dart';

void main() {
  testWidgets('TravelModeSelector muestra los cuatro modos de transporte', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TravelModeSelector(selectedMode: TransportMode.driving),
        ),
      ),
    );

    expect(find.text('Vehículo'), findsOneWidget);
    expect(find.text('A pie'), findsOneWidget);
    expect(find.text('Bicicleta'), findsOneWidget);
    expect(find.text('Transporte público'), findsOneWidget);
    expect(find.text('Sin rutas disponibles'), findsNWidgets(2));
    expect(find.text('Datos no integrados'), findsOneWidget);
    expect(find.text('Se evalúa al analizar'), findsOneWidget);
  });

  testWidgets('salida programada muestra estados sin datos horarios', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TravelModeSelector(
            selectedMode: TransportMode.driving,
            scheduled: true,
          ),
        ),
      ),
    );

    expect(find.text('Sin datos horarios'), findsOneWidget);
    expect(find.text('Disponible'), findsNothing);
    expect(find.text('Sin rutas disponibles'), findsNWidgets(2));
    expect(find.text('Datos no integrados'), findsOneWidget);
  });

  testWidgets(
    'seleccionar Vehículo invoca onModeSelected y no modos en desarrollo',
    (tester) async {
      TransportMode? selected;
      TransportMode? unavailable;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TravelModeSelector(
              selectedMode: TransportMode.driving,
              onModeSelected: (mode) => selected = mode,
              onUnavailableModeTap: (mode) => unavailable = mode,
            ),
          ),
        ),
      );

      // Tap Vehículo
      await tester.tap(find.text('Vehículo'));
      await tester.pump();
      expect(selected, TransportMode.driving);
      expect(unavailable, isNull);

      // Tap A pie
      await tester.tap(find.text('A pie'));
      await tester.pump();
      expect(unavailable, TransportMode.walking);

      // Tap Bicicleta
      await tester.tap(find.text('Bicicleta'));
      await tester.pump();
      expect(unavailable, TransportMode.cycling);

      // Tap Transporte público
      await tester.ensureVisible(find.text('Transporte público'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transporte público'));
      await tester.pump();
      expect(unavailable, TransportMode.publicTransport);
    },
  );

  testWidgets(
    'tap en modo no disponible sin callback muestra SnackBar informativo',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TravelModeSelector(selectedMode: TransportMode.driving),
          ),
        ),
      );

      await tester.tap(find.text('A pie'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Aún no hay rutas disponibles para a pie.'),
        findsOneWidget,
      );
    },
  );

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'TravelModeSelector es responsive y accesible a ${width.toInt()} px con texto 1.5x',
      (tester) async {
        tester.view.physicalSize = Size(width, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const Scaffold(
              body: TravelModeSelector(selectedMode: TransportMode.driving),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Vehículo'), findsOneWidget);
        expect(
          tester.getSemantics(find.text('Vehículo')).label,
          contains('Vehículo'),
        );
        expect(
          tester.getSemantics(find.text('A pie')).label,
          contains('Sin rutas disponibles'),
        );

        semantics.dispose();
      },
    );
  }
}
