import 'dart:ui' show Tristate;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/services/osrm_routing_service.dart';
import 'package:transporte_inteligente/widgets/route_alternatives_selector.dart';

RouteResult candidate(int index) => RouteResult(
  origin: const LatLng(7.1, -73.1),
  destination: const LatLng(7.2, -73.2),
  points: const [LatLng(7.1, -73.1), LatLng(7.2, -73.2)],
  distanceMeters: (index + 1) * 1000,
  durationSeconds: (index + 1) * 120,
);

void main() {
  RouteResult metrics(double meters, double seconds) => RouteResult(
    origin: candidate(0).origin,
    destination: candidate(0).destination,
    points: candidate(0).points,
    distanceMeters: meters,
    durationSeconds: seconds,
  );

  Future<void> open(WidgetTester tester, List<RouteResult> alternatives) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteAlternativesSelector(
            alternatives: alternatives,
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Cambiar alternativa'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'etiquetas y diferencias usan mínimos independientes con semántica',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester, [metrics(7400, 1140), metrics(8600, 900)]);
      final first = find.widgetWithText(ListTile, 'Alternativa 1');
      final second = find.widgetWithText(ListTile, 'Alternativa 2');
      expect(
        find.descendant(
          of: first,
          matching: find.textContaining('Más corta · +4 min'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: second,
          matching: find.textContaining('Más rápida · +1.2 km'),
        ),
        findsOneWidget,
      );
      expect(tester.getSemantics(first).label, contains('Más corta'));
      expect(tester.getSemantics(second).label, contains('Más rápida'));
      expect(find.textContaining('Recomendada'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'una opción muestra ambas etiquetas y los empates respetan orden',
    (tester) async {
      await open(tester, [metrics(1000, 120), metrics(1000, 120)]);
      expect(find.textContaining('Más rápida · Más corta'), findsOneWidget);
      expect(find.textContaining('+0'), findsNothing);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Alternativa 1'),
          matching: find.textContaining('Más rápida'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'diferencias pequeñas y horas no muestran ceros ni falsa precisión',
    (tester) async {
      await open(tester, [
        metrics(1000, 120),
        metrics(1000.4, 120.4),
        metrics(1250, 4020),
      ]);
      expect(find.textContaining('<1 min'), findsOneWidget);
      expect(find.textContaining('<1 m'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Alternativa 3'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('+1 h 5 min'), findsOneWidget);
      expect(find.textContaining('+250 m'), findsOneWidget);
      expect(
        find.textContaining('Duración estimada: 1 h 7 min'),
        findsOneWidget,
      );
      expect(find.textContaining('+0'), findsNothing);
    },
  );

  testWidgets('sin candidatas no ofrece controles ni una selección ficticia', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RouteAlternativesSelector(
          alternatives: const [],
          selectedIndex: 0,
          onSelected: (_) => fail('No selection'),
        ),
      ),
    );
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.textContaining('seleccionada'), findsNothing);
  });

  testWidgets(
    'seleccionar rutas obtenidas por OSRM no hace otra consulta HTTP',
    (tester) async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        expect(request.url.queryParameters['alternatives'], 'true');
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              for (final distance in [1000, 2000])
                {
                  'distance': distance,
                  'duration': distance / 10,
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [-73.1, 7.1],
                      [-73.2, 7.2],
                    ],
                  },
                },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);
      final routes = await OsrmRoutingService(client: client).routeAlternatives(
        origin: candidate(0).origin,
        destination: candidate(0).destination,
      );
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => RouteAlternativesSelector(
                alternatives: routes,
                selectedIndex: selected,
                onSelected: (index) => setState(() => selected = index),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Cambiar alternativa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alternativa 2'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(find.text('Alternativa 2 de 2 seleccionada'), findsOneWidget);
      expect(requests, 1);
      expect(routes[1].distanceMeters, 2000);
      expect(routes[1].durationSeconds, 200);
    },
  );

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
    expect(find.textContaining('Más rápida'), findsNothing);
    expect(find.textContaining('Más corta'), findsNothing);
    expect(find.textContaining('+0'), findsNothing);
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
