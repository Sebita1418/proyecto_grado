import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/widgets/route_alternatives_selector.dart';

RouteResult candidate(int index) => RouteResult(
  origin: const LatLng(7.1, -73.1),
  destination: const LatLng(7.2, -73.2),
  points: const [LatLng(7.1, -73.1), LatLng(7.2, -73.2)],
  distanceMeters: (index + 1) * 1000,
  durationSeconds: (index + 1) * 120,
);

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'selector accesible y compacto a $width px con texto ampliado',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        try {
          final selections = <int>[];
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: width < 420 ? width : 420,
                    child: RouteAlternativesSelector(
                      alternatives: List.generate(12, candidate),
                      selectedIndex: 0,
                      onSelected: selections.add,
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(find.text('Alternativa 1 de 12 seleccionada'), findsOneWidget);
          expect(
            tester.getSize(find.byType(RouteAlternativesSelector)).height,
            lessThan(tester.view.physicalSize.height / 4),
          );
          await tester.tap(find.text('Cambiar alternativa'));
          await tester.pumpAndSettle();
          expect(find.textContaining('Seleccionada'), findsOneWidget);
          expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
          final selected = find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.selected == true,
          );
          expect(selected, findsOneWidget);
          expect(
            tester.getSemantics(selected).flagsCollection.isSelected,
            Tristate.isTrue,
          );
          expect(
            find.textContaining('1.0 km · Duración estimada: 2 min'),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.text('Alternativa 12'),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Alternativa 12'));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('12.0 km · Duración estimada: 24 min'),
            findsOneWidget,
          );
          await tester.tap(find.text('Alternativa 12'));
          await tester.pumpAndSettle();
          expect(selections, [11]);
          expect(find.text('Alternativas de ruta vehicular'), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('una ruta no ofrece un selector ficticio', (tester) async {
    final selections = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteAlternativesSelector(
            alternatives: [candidate(0)],
            selectedIndex: 0,
            onSelected: selections.add,
          ),
        ),
      ),
    );
    expect(find.text('Se recibió una sola ruta vehicular.'), findsOneWidget);
    expect(find.text('Cambiar alternativa'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(selections, isEmpty);
  });

  testWidgets('cerrar la lista no cambia la selección', (tester) async {
    final selections = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteAlternativesSelector(
            alternatives: [candidate(0), candidate(1)],
            selectedIndex: 1,
            onSelected: selections.add,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Cambiar alternativa'));
    await tester.pumpAndSettle();
    final secondTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Alternativa 2'),
    );
    expect(secondTile.selected, isTrue);
    Navigator.of(tester.element(find.text('Alternativas de ruta vehicular')))
        .pop();
    await tester.pumpAndSettle();
    expect(find.text('Alternativa 2 de 2 seleccionada'), findsOneWidget);
    expect(selections, isEmpty);
  });
}
