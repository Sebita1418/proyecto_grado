import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/screens/nearby/nearby_places_screen.dart';

void main() {
  testWidgets('categorías cambian la selección sin fabricar resultados', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NearbyPlacesScreen()));
    expect(find.text('Puntos cercanos'), findsOneWidget);
    for (final category in [
      'Transporte',
      'Salud',
      'Parqueaderos',
      'Servicios',
    ]) {
      expect(find.text(category), findsOneWidget);
      await tester.tap(find.text(category));
      await tester.pump();
      expect(find.text('Categoría elegida: $category'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, category))
            .selected,
        isTrue,
      );
      expect(find.text('Aún no disponible'), findsOneWidget);
      expect(
        find.text(
          'Todavía no contamos con información de lugares cercanos. '
          'Podrás consultarlos aquí cuando esa información esté disponible.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Por ahora, elegir una categoría no realiza una búsqueda.'),
        findsOneWidget,
      );
      // La única tarjeta es informativa: no hay lista de establecimientos,
      // distancias, horarios ni una carga simulada al elegir categorías.
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining(RegExp(r'\d+\s*(km|min|m)\b')), findsNothing);
    }
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('sin overflow a $width px y texto ampliado', (tester) async {
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
          home: const NearbyPlacesScreen(),
        ),
      );
      await tester.ensureVisible(find.text('Volver al mapa'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Volver al mapa').hitTestable(), findsOneWidget);
    });
  }
}
