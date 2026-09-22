import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/models/perfil_model.dart';
import 'package:transporte_inteligente/screens/perfil/perfil_screen.dart';
import 'package:transporte_inteligente/screens/preferences/mobility_preferences_screen.dart';

void main() {
  testWidgets(
    'Perfil abre preferencias; salir descarta la confirmación local',
    (tester) async {
      final perfil = Perfil(
        id: 'usuario-1',
        nombre: 'Brayan',
        correo: 'brayan@example.com',
        rol: 'usuario',
        activo: true,
      );
      await tester.pumpWidget(MaterialApp(home: PerfilScreen(perfil: perfil)));
      await tester.ensureVisible(find.text('Preferencias de movilidad'));
      await tester.tap(find.text('Preferencias de movilidad'));
      await tester.pumpAndSettle();
      expect(find.byType(MobilityPreferencesScreen), findsOneWidget);
      await tester.ensureVisible(find.text('A pie'));
      await tester.tap(find.text('A pie'));
      await tester.pump();
      await tester.ensureVisible(find.text('Confirmar selección'));
      await tester.tap(find.text('Confirmar selección'));
      await tester.pump();
      expect(
        find.text('Preferencias confirmadas en esta pantalla.'),
        findsOneWidget,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Mi perfil'), findsOneWidget);
      await tester.ensureVisible(find.text('Preferencias de movilidad'));
      await tester.tap(find.text('Preferencias de movilidad'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'A pie'),
            )
            .value,
        isFalse,
      );
      expect(
        find.text('Selecciona al menos un modo para confirmar.'),
        findsOneWidget,
      );
    },
  );

  group('PerfilScreen', () {
    testWidgets('muestra correctamente la información del perfil', (
      tester,
    ) async {
      final perfil = Perfil(
        id: 'usuario-1',
        nombre: 'Brayan Jurado',
        correo: 'brayan@example.com',
        rol: 'usuario',
        activo: true,
      );

      await tester.pumpWidget(MaterialApp(home: PerfilScreen(perfil: perfil)));

      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Brayan Jurado'), findsNWidgets(2));
      expect(find.text('brayan@example.com'), findsNWidgets(2));
      expect(find.text('Usuario'), findsOneWidget);

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Rol'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Estado de la cuenta'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Activa'), findsOneWidget);
      expect(find.text('Estado de la cuenta'), findsOneWidget);
    });

    testWidgets('muestra una cuenta inactiva correctamente', (tester) async {
      final perfil = Perfil(
        id: 'administrador-1',
        nombre: 'Sebastián',
        correo: 'sebastian@example.com',
        rol: 'administrador',
        activo: false,
      );

      await tester.pumpWidget(MaterialApp(home: PerfilScreen(perfil: perfil)));

      expect(find.text('Sebastián'), findsNWidgets(2));
      expect(find.text('Administrador'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Estado de la cuenta'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Inactiva'), findsOneWidget);
      expect(find.byIcon(Icons.block_outlined), findsOneWidget);
    });
  });
}
