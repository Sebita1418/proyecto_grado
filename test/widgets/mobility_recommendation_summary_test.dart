import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/decision/current_mobility_decision_adapter.dart';
import 'package:transporte_inteligente/mobility/decision/departure_time_context.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_decision_coordinator.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/route_incident_analysis.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/widgets/mobility_recommendation_summary.dart';

void main() {
  Future<void> render(
    WidgetTester tester, {
    bool manual = false,
    int selected = 1,
    bool defaults = false,
    bool compact = false,
    bool showEvidence = false,
    bool reportsSnapshotAvailable = false,
  }) async {
    const origin = LatLng(7.1, -73.1);
    const destination = LatLng(7.2, -73.2);
    final option = RouteOption.fromRouteResult(
      id: 'one',
      mode: TransportMode.driving,
      source: 'osrm',
      route: const RouteResult(
        origin: origin,
        destination: destination,
        points: [origin, destination],
        distanceMeters: 1000,
        durationSeconds: 120,
      ),
    );
    final baseTrip = MobilityContext(
      origin: origin,
      destination: destination,
      allowedModes: {TransportMode.driving},
      requestedAt: DateTime.utc(2026),
    );
    final result = await VehicleRecommendationEngine().recommend(baseTrip, [
      option,
    ]);
    final reportSnapshot = reportsSnapshotAvailable
        ? RouteIncidentAnalysis(
            routeId: 'one',
            evaluatedAt: DateTime.now().toUtc(),
            incidents: const [],
          )
        : null;
    final trip = MobilityContext(
      origin: origin,
      destination: destination,
      allowedModes: {TransportMode.driving},
      requestedAt: DateTime.utc(2026),
      incidentAnalyses: {
        ...?(reportSnapshot == null ? null : {'one': reportSnapshot}),
      },
    );
    final decisionContext = const CurrentMobilityDecisionAdapter().build(
      trip: trip,
      departure: DepartureTimeContext.now(DateTime.now()),
      routes: [option],
    );
    final decision = const MobilityDecisionCoordinator().decide(
      decisionContext,
      vehicleRecommendation: result,
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MobilityRecommendationSummary(
              compact: compact,
              recommendation: result,
              decision: showEvidence ? decision : null,
              incidentAnalyses: reportSnapshot == null
                  ? const []
                  : [reportSnapshot],
              suggestedIndex: 1,
              selectedIndex: selected,
              manuallySelected: manual,
              usesDefaultModes: defaults,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('evidencia distingue fuente disponible de no disponible', (
    tester,
  ) async {
    await render(tester, compact: true, showEvidence: true);
    await tester.tap(find.text('¿Por qué esta ruta?'));
    await tester.pumpAndSettle();
    expect(
      find.text('Rutas y métricas: OSRM; estimaciones del proveedor.'),
      findsOneWidget,
    );
    expect(
      find.text('Reportes viales próximos: No disponible en esta consulta.'),
      findsOneWidget,
    );
    expect(find.text('Tráfico en tiempo real: no disponible.'), findsOneWidget);
    expect(find.textContaining('Sin reportes activos próximos'), findsNothing);

    // Reset the widget tree so the next ExpansionTile starts collapsed.
    await tester.pumpWidget(const SizedBox.shrink());
    await render(
      tester,
      compact: true,
      showEvidence: true,
      reportsSnapshotAvailable: true,
    );
    await tester.tap(find.text('¿Por qué esta ruta?'));
    await tester.pumpAndSettle();
    expect(
      find.text('Reportes viales próximos: Sin reportes activos próximos.'),
      findsOneWidget,
    );
  });

  testWidgets('resumen compacto abre motivos reales sin cambiar selección', (
    tester,
  ) async {
    await render(
      tester,
      compact: true,
      manual: true,
      selected: 0,
      defaults: true,
    );
    expect(find.textContaining('Única alternativa'), findsNothing);
    expect(find.text('Selección manual'), findsOneWidget);
    expect(find.text('Seleccionada: alternativa 1'), findsOneWidget);
    expect(find.text('RUTA SUGERIDA'), findsOneWidget);
    await tester.tap(find.text('¿Por qué esta ruta?'));
    await tester.pumpAndSettle();
    expect(find.text('Análisis de movilidad'), findsOneWidget);
    expect(find.text('Alternativa 2 · 2 min · 1,0 km'), findsOneWidget);
    expect(find.textContaining('Única alternativa'), findsOneWidget);
    expect(find.textContaining('por defecto'), findsOneWidget);
    expect(tester.getSize(find.byType(Card)).width, lessThanOrEqualTo(450));
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('sugerencia legible y accesible a $width con texto ampliado', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await render(tester, defaults: true);
      expect(find.text('Ruta sugerida'), findsOneWidget);
      expect(find.textContaining('Única alternativa'), findsOneWidget);
      expect(find.textContaining('por defecto'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Ruta sugerida')).label,
        contains('Ruta sugerida'),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('selección manual distinta no se presenta como sugerencia', (
    tester,
  ) async {
    await render(tester, manual: true, selected: 0);
    expect(find.text('Ruta sugerida'), findsNothing);
    expect(find.text('Selección manual'), findsOneWidget);
    expect(find.textContaining('Elegiste la alternativa 1.'), findsOneWidget);
    expect(find.textContaining('fue la alternativa 2'), findsOneWidget);
    expect(find.textContaining('Motivo de la sugerencia:'), findsOneWidget);
  });

  testWidgets(
    'volver manualmente a la sugerida conserva autoría de selección',
    (tester) async {
      await render(tester, manual: true);
      expect(find.text('Ruta sugerida'), findsNothing);
      expect(find.textContaining('coincide con la sugerencia'), findsOneWidget);
      expect(find.textContaining('por defecto'), findsNothing);
    },
  );
}
