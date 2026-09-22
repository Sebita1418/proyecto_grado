import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/screens/preferences/mobility_preferences_screen.dart';

void main() {
  Future<void> render(
    WidgetTester tester, {
    ValueChanged<Set<TransportMode>>? onConfirmed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(home: MobilityPreferencesScreen(onConfirmed: onConfirmed)),
    );
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
  }

  testWidgets('estado inicial sin preferencias supuestas ni promesas falsas', (
    tester,
  ) async {
    await render(tester);
    expect(find.text('Preferencias de movilidad'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(4));
    for (final tile in tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    )) {
      expect(tile.value, isFalse);
    }
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.textContaining('todavía no cambia las rutas'), findsOneWidget);
    expect(find.textContaining('no se guarda en tu cuenta'), findsOneWidget);
    for (final promise in [
      'Ruta optimizada',
      'Recomendación inteligente aplicada',
      'Ahorro',
      'Mejor ruta para ti',
    ]) {
      expect(find.textContaining(promise), findsNothing);
    }
  });

  testWidgets('selección confirmada usa los modos del contrato existente', (
    tester,
  ) async {
    final selections = <Set<TransportMode>>[];
    await render(tester, onConfirmed: selections.add);
    const labels = {
      'En vehículo': TransportMode.driving,
      'A pie': TransportMode.walking,
      'En bicicleta': TransportMode.cycling,
      'Transporte público': TransportMode.publicTransport,
    };
    final expected = <TransportMode>{};
    for (final entry in labels.entries) {
      await tap(tester, entry.key);
      expected.add(entry.value);
      await tap(tester, 'Confirmar selección');
      expect(selections.last, expected);
      expect(
        find.text('Preferencias confirmadas en esta pantalla.'),
        findsOneWidget,
      );
    }
    final confirmed = selections.last;
    expect(() => confirmed.clear(), throwsUnsupportedError);
    // Datos de prueba del viaje; la UI no inventa un contexto en producción.
    final context = MobilityContext(
      origin: const LatLng(7.1, -73.1),
      destination: const LatLng(7.2, -73.2),
      allowedModes: confirmed,
      requestedAt: DateTime.utc(2026, 9, 17),
    );
    expect(context.allowedModes, TransportMode.values.toSet());
    expect(context.generalConditions.isUnknown, isTrue);
    await tap(tester, 'A pie');
    expect(confirmed, TransportMode.values.toSet());
    expect(context.allowedModes, confirmed);
    expect(selections.length, 4);
  });

  testWidgets('vacío no confirma y deshacer recupera lo confirmado', (
    tester,
  ) async {
    final selections = <Set<TransportMode>>[];
    await render(tester, onConfirmed: selections.add);
    await tap(tester, 'A pie');
    await tap(tester, 'Deshacer cambios');
    expect(selections, isEmpty);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tap(tester, 'En bicicleta');
    await tap(tester, 'Confirmar selección');
    await tap(tester, 'En bicicleta');
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(selections, [
      {TransportMode.cycling},
    ]);
    await tap(tester, 'Deshacer cambios');
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'En bicicleta'),
          )
          .value,
      isTrue,
    );
    expect(
      find.text('Preferencias confirmadas en esta pantalla.'),
      findsOneWidget,
    );
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('selección accesible sin overflow a $width px', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const MobilityPreferencesScreen(),
        ),
      );
      await tap(tester, 'Transporte público');
      await tap(tester, 'Confirmar selección');
      expect(
        find.text('Preferencias confirmadas en esta pantalla.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
