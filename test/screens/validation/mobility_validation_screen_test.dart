import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/mobility/validation/mobility_validation.dart';
import 'package:transporte_inteligente/screens/validation/mobility_validation_screen.dart';
import 'package:transporte_inteligente/theme/mobility_theme.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';

import '../home/route_flow_test.dart'
    show
        ControlledRouting,
        FixedGeocoding,
        FixedSuggestions,
        firstRoute,
        secondRoute;
import '../../mobility/validation/mobility_validation_test.dart' as fixtures;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('real snapshot responsive $width, manual different', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final snapshot = await fixtures.evaluate(
        [fixtures.option('a', 100, 1000), fixtures.option('b', 120, 800)],
        fixtures.context(
          analyses: [
            fixtures.analysis('a', 1, closures: 1),
            fixtures.analysis('b', 0),
          ],
        ),
        selected: 'a',
        manual: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: MobilityTheme.light,
          home: MobilityValidationScreen(snapshot: snapshot),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Validación de recomendación'), findsOneWidget);
      expect(
        find.text('Sugerida por el sistema: Alternativa 2'),
        findsOneWidget,
      );
      expect(
        find.text('Seleccionada por el usuario: Alternativa 1'),
        findsOneWidget,
      );
      expect(
        find.text('Diferencia frente a la más rápida: 20.0 %'),
        findsOneWidget,
      );
      for (var i = 0; i < 16; i++) {
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -350),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Criterios evaluados'), findsOneWidget);
      expect(find.text('Comparación'), findsOneWidget);
      expect(find.text('Evidencia disponible'), findsOneWidget);
      expect(
        find.text(
          'Proximidad no confirma bloqueo, retraso ni flujo vehicular. Desconocido no significa ausencia.',
        ),
        findsOneWidget,
      );
    });
  }
  testWidgets('unknown and one route are honest', (tester) async {
    final snapshot = await fixtures.evaluate([
      fixtures.option('a', 100, 1000),
    ], fixtures.context());
    await tester.pumpWidget(
      MaterialApp(
        theme: MobilityTheme.light,
        home: MobilityValidationScreen(snapshot: snapshot),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alternativas evaluadas: 1'), findsOneWidget);
    expect(
      find.text('Reportes próximos en la sugerida: Desconocido'),
      findsOneWidget,
    );
    expect(find.text('Posición por duración: 1'), findsOneWidget);
    expect(find.textContaining('! No evaluable'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('no recommendation does not become a technical failure', (
    tester,
  ) async {
    final snapshot = const MobilityValidationEvaluator().evaluate(
      fixtures.project(fixtures.context(), [], null),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: MobilityTheme.light,
        home: MobilityValidationScreen(snapshot: snapshot),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sin recomendación'), findsOneWidget);
    expect(
      find.text('No hubo alternativas elegibles para recomendación.'),
      findsOneWidget,
    );
    expect(find.text('Alternativas evaluadas: 0'), findsOneWidget);
    expect(find.textContaining('× No cumple'), findsNothing);
  });
  testWidgets(
    'planner opens observed validation without new routing or changing selection',
    (tester) async {
      final routing = ControlledRouting();
      final geocoding = FixedGeocoding();
      final suggestions = FixedSuggestions();
      addTearDown(routing.dispose);
      addTearDown(geocoding.dispose);
      addTearDown(suggestions.dispose);
      final changes = <RouteResult?>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: MobilityTheme.light,
          home: Scaffold(
            body: MapSearchPanel(
              currentPosition: firstRoute.origin,
              locationStatus: LocationStatus.coordinatesObtained,
              routingService: routing,
              geocodingService: geocoding,
              placeSuggestionService: suggestions,
              onRouteChanged: changes.add,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, 'Destino');
      await tester.ensureVisible(find.text('Analizar rutas'));
      await tester.tap(find.text('Analizar rutas'));
      await tester.pump();
      routing.pending.complete([firstRoute, secondRoute]);
      await tester.pumpAndSettle();
      final changesBefore = changes.length;
      await tester.ensureVisible(find.text('Validación de recomendación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validación de recomendación'));
      await tester.pumpAndSettle();
      expect(find.byType(MobilityValidationScreen), findsOneWidget);
      expect(
        find.text('Sugerida por el sistema: Alternativa 2'),
        findsOneWidget,
      );
      expect(
        find.text('Seleccionada en el flujo: Alternativa 1'),
        findsOneWidget,
      );
      expect(routing.calls, 1);
      expect(changes.length, changesBefore);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(MapSearchPanel), findsOneWidget);
      expect(routing.calls, 1);
      expect(changes.length, changesBefore);
    },
  );
}
