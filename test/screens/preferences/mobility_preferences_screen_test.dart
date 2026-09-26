import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/screens/preferences/mobility_preferences_screen.dart';
import 'package:transporte_inteligente/services/mobility_preferences_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> render(
    WidgetTester tester, {
    ValueChanged<Set<TransportMode>>? onConfirmed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(home: MobilityPreferencesScreen(onConfirmed: onConfirmed)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  bool selected(WidgetTester tester, String label) => tester
      .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, label))
      .value!;

  testWidgets('carga agotada libera la pantalla e ignora respuesta tardía', (
    tester,
  ) async {
    final pending = Completer<SharedPreferences>();
    final service = MobilityPreferencesService(
      preferencesLoader: () => pending.future,
    );
    await tester.pumpWidget(
      MaterialApp(home: MobilityPreferencesScreen(service: service)),
    );
    await tester.pump(const Duration(seconds: 8));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('No se pudieron cargar'), findsOneWidget);
    await tap(tester, 'En bicicleta');
    SharedPreferences.setMockInitialValues({
      MobilityPreferencesService.storageKey: ['walking'],
    });
    pending.complete(await SharedPreferences.getInstance());
    await tester.pumpAndSettle();
    expect(selected(tester, 'En bicicleta'), isTrue);
    expect(selected(tester, 'A pie'), isFalse);
  });

  testWidgets('guardado pendiente bloquea duplicados y salir es seguro', (
    tester,
  ) async {
    final service = ControlledPreferencesService()..saving = Completer<void>();
    final callbacks = <Set<TransportMode>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MobilityPreferencesScreen(
          service: service,
          onConfirmed: callbacks.add,
        ),
      ),
    );
    service.loading.complete({TransportMode.walking});
    await tester.pumpAndSettle();
    await tap(tester, 'En bicicleta');
    await tester.ensureVisible(find.text('Confirmar selección'));
    await tester.tap(find.text('Confirmar selección'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    expect(
      tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .every((tile) => tile.onChanged == null),
      isTrue,
    );
    expect(callbacks, isEmpty);
    await tester.pumpWidget(const SizedBox());
    service.saving!.complete();
    await tester.pump();
    expect(service.saved, {TransportMode.walking, TransportMode.cycling});
    expect(tester.takeException(), isNull);
    expect(callbacks, isEmpty);
  });

  testWidgets('carga, confirma y reabre sin persistir cambios temporales', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      MobilityPreferencesService.storageKey: ['walking'],
    });
    await render(tester);
    expect(selected(tester, 'A pie'), isTrue);
    await tap(tester, 'En bicicleta');
    await tap(tester, 'Deshacer cambios');
    expect(selected(tester, 'A pie'), isTrue);
    expect(selected(tester, 'En bicicleta'), isFalse);
    await tap(tester, 'En bicicleta');
    await tap(tester, 'Confirmar selección');
    expect(await const MobilityPreferencesService().load(), {
      TransportMode.walking,
      TransportMode.cycling,
    });
    await tap(tester, 'En vehículo');
    await tester.pumpWidget(const SizedBox());
    await render(tester);
    expect(selected(tester, 'A pie'), isTrue);
    expect(selected(tester, 'En bicicleta'), isTrue);
    expect(selected(tester, 'En vehículo'), isFalse);
  });

  testWidgets('carga pendiente muestra progreso y salir es seguro', (
    tester,
  ) async {
    final service = ControlledPreferencesService();
    await tester.pumpWidget(
      MaterialApp(home: MobilityPreferencesScreen(service: service)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    await tester.pumpWidget(const SizedBox());
    service.loading.complete({TransportMode.walking});
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('fallo de carga permite elegir y guardar sin crash', (
    tester,
  ) async {
    final service = ControlledPreferencesService();
    await tester.pumpWidget(
      MaterialApp(home: MobilityPreferencesScreen(service: service)),
    );
    service.loading.completeError(const MobilityPreferencesStorageException());
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudieron cargar'), findsOneWidget);
    await tap(tester, 'A pie');
    await tap(tester, 'Confirmar selección');
    expect(service.saved, {TransportMode.walking});
    expect(
      find.text('Preferencias guardadas en este dispositivo.'),
      findsOneWidget,
    );
  });

  testWidgets('fallo al guardar conserva confirmación y permite reintentar', (
    tester,
  ) async {
    final service = ControlledPreferencesService()..failSave = true;
    final callbacks = <Set<TransportMode>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MobilityPreferencesScreen(
          service: service,
          onConfirmed: callbacks.add,
        ),
      ),
    );
    service.loading.complete({TransportMode.walking});
    await tester.pumpAndSettle();
    await tap(tester, 'En bicicleta');
    await tap(tester, 'Confirmar selección');
    expect(find.textContaining('No se pudieron guardar'), findsOneWidget);
    expect(callbacks, isEmpty);
    await tap(tester, 'Deshacer cambios');
    expect(selected(tester, 'A pie'), isTrue);
    expect(selected(tester, 'En bicicleta'), isFalse);
    await tap(tester, 'En bicicleta');
    service.failSave = false;
    await tap(tester, 'Confirmar selección');
    expect(callbacks.single, {TransportMode.walking, TransportMode.cycling});
  });

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
    expect(
      find.textContaining('Los cambios se aplican al volver a calcular'),
      findsOneWidget,
    );
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
        find.text('Preferencias guardadas en este dispositivo.'),
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
      find.text('Preferencias guardadas en este dispositivo.'),
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
      await tester.pumpAndSettle();
      await tap(tester, 'Transporte público');
      await tap(tester, 'Confirmar selección');
      expect(
        find.text('Preferencias guardadas en este dispositivo.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

class ControlledPreferencesService extends MobilityPreferencesService {
  final loading = Completer<Set<TransportMode>>();
  Completer<void>? saving;
  bool failSave = false;
  Set<TransportMode>? saved;

  @override
  Future<Set<TransportMode>> load() => loading.future;

  @override
  Future<void> save(Set<TransportMode> modes) async {
    if (saving != null) await saving!.future;
    if (failSave) throw const MobilityPreferencesStorageException();
    saved = Set.of(modes);
  }
}
