import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/models/incident_report_draft.dart';
import 'package:transporte_inteligente/models/route_insight.dart';
import 'package:transporte_inteligente/widgets/mobility_recommendation_summary.dart';

import '../models/route_insight_test.dart' show insightFor, snapshot;

Widget card(RouteInsight insight, {bool updating = false}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(1.5)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: MobilityRecommendationSummary(
        compact: true,
        recommendation: insight.recommendation,
        incidentAnalyses: [if (insight.analysis != null) insight.analysis!],
        suggestedIndex: insight.recommendation.recommended.id == 'a' ? 0 : 1,
        selectedIndex: 0,
        manuallySelected: true,
        usesDefaultModes: false,
        updating: updating,
      ),
    ),
  ),
);

void main() {
  for (final width in [390.0, 768.0, 1440.0]) {
    testWidgets('tarjeta y detalle sin overflow a $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final insight = await insightFor(
        analyses: [snapshot('a'), snapshot('b')],
      );
      await tester.pumpWidget(card(insight));
      expect(find.text('Ruta sugerida'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Ruta sugerida')).label,
        contains('Ruta sugerida'),
      );
      expect(find.text('Sin reportes próximos'), findsOneWidget);
      expect(tester.getSize(find.byType(Card)).width, lessThanOrEqualTo(450));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('¿Por qué esta ruta?'));
      await tester.pumpAndSettle();
      expect(find.text('Duración: 12 min'), findsOneWidget);
      expect(find.text('Distancia: 7,4 km'), findsOneWidget);
      expect(find.text('Reportes próximos: 0'), findsOneWidget);
      expect(find.text('Cierres próximos: 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('¿Por qué esta ruta?'));
      await tester.tap(find.text('¿Por qué esta ruta?'));
      await tester.pumpAndSettle();
      expect(find.text('Análisis de movilidad'), findsNothing);
      expect(find.text('Ruta sugerida'), findsOneWidget);
      semantics.dispose();
    });
  }

  testWidgets('detalle abierto se actualiza y conserva selección manual', (
    tester,
  ) async {
    final initial = await insightFor(analyses: [snapshot('a'), snapshot('b')]);
    await tester.pumpWidget(card(initial));
    await tester.tap(find.text('¿Por qué esta ruta?'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(card(initial, updating: true));
    expect(find.text('Actualizando condiciones reportadas…'), findsOneWidget);
    expect(find.text('Sin cierres reportados próximos'), findsNothing);
    final updated = await insightFor(
      analyses: [snapshot('a', IncidentType.roadClosed), snapshot('b')],
    );
    await tester.pumpWidget(card(updated));
    await tester.pumpAndSettle();
    expect(find.text('Alternativa 2 · 13 min · 7,1 km'), findsOneWidget);
    expect(find.text('Seleccionada: alternativa 1'), findsOneWidget);
    expect(find.text('Selección manual'), findsOneWidget);
    expect(find.text('Análisis de movilidad'), findsOneWidget);
    expect(
      find.textContaining('Se prioriza una alternativa sin cierres'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
