import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/mobility_recommendation.dart';
import 'package:transporte_inteligente/mobility/mobility_recommendation_engine.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/models/road_incident_report.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';
import 'package:transporte_inteligente/widgets/mobility_recommendation_summary.dart';
import 'package:transporte_inteligente/widgets/route_incident_status.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';

import '../../reports/road_incident_test.dart'
    show FakeRoadIncidents, reportRow;
import 'route_flow_test.dart'
    show
        ControlledRouting,
        FixedLocation,
        FixedGeocoding,
        FixedSuggestions,
        firstRoute,
        secondRoute,
        tapLabel;

RoadIncidentReport closureOnSecond() => RoadIncidentReport.fromMap({
  ...reportRow(),
  'tipo': 'road_closed',
  'latitud': 7.18,
  'longitud': -73.12,
});

class PendingIncidentEngine implements MobilityRecommendationEngine {
  final requests =
      <
        (MobilityContext, List<RouteOption>, Completer<MobilityRecommendation>)
      >[];
  @override
  Future<MobilityRecommendation> recommend(
    MobilityContext context,
    List<RouteOption> options,
  ) {
    final pending = Completer<MobilityRecommendation>();
    requests.add((context, options, pending));
    return pending.future;
  }

  Future<void> complete(int index) async {
    final request = requests[index];
    request.$3.complete(
      await VehicleRecommendationEngine().recommend(request.$1, request.$2),
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> calculate(WidgetTester tester, ControlledRouting routing) async {
    await tester.enterText(find.byType(TextField).last, 'Destino');
    await tester.ensureVisible(find.text('Calcular ruta'));
    await tester.tap(find.text('Calcular ruta'));
    await tester.pump();
    routing.pending.complete([firstRoute, secondRoute]);
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 768.0]) {
    testWidgets(
      'Realtime actualiza selector abierto a $width, conserva selección y no llama OSRM',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final reports = FakeRoadIncidents();
        final routing = ControlledRouting();
        await tester.pumpWidget(
          MaterialApp(
            home: HomeScreen(
              locationService: FixedLocation(),
              loadProfile: () async => null,
              geocodingService: FixedGeocoding(),
              placeSuggestionService: FixedSuggestions(),
              routingService: routing,
              roadIncidentService: reports,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await calculate(tester, routing);
        expect(find.text('Sin reportes activos próximos'), findsOneWidget);
        expect(
          tester
              .widget<MobilityRecommendationSummary>(
                find.byType(MobilityRecommendationSummary),
              )
              .suggestedIndex,
          1,
        );
        await tapLabel(tester, 'Cambiar alternativa');
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('Sin reportes activos próximos'),
          ),
          findsNWidgets(2),
        );
        await tapLabel(tester, 'Alternativa 2');
        final points = tester
            .widget<RouteMap>(find.byType(RouteMap))
            .polylines
            .last
            .points
            .toList();
        await tapLabel(tester, 'Cambiar alternativa');
        reports.rows = [closureOnSecond()];
        reports.events.add(null);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 351));
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.textContaining(
              'Cierre vial reportado próximo al recorrido',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text('Sin reportes activos próximos'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.textContaining('1 reporte activo próximo'),
          ),
          findsOneWidget,
        );
        expect(routing.calls, 1);
        // Close without selecting a different alternative.
        Navigator.of(
          tester.element(find.text('Alternativas de ruta vehicular')),
        ).pop();
        await tester.pumpAndSettle();
        var summary = tester.widget<MobilityRecommendationSummary>(
          find.byType(MobilityRecommendationSummary),
        );
        expect(summary.suggestedIndex, 0);
        expect(summary.selectedIndex, 1);
        expect(summary.manuallySelected, isTrue);
        expect(
          tester.widget<RouteMap>(find.byType(RouteMap)).polylines.last.points,
          points,
        );
        await tester.ensureVisible(find.byType(MobilityRecommendationSummary));
        await tester.tap(find.text('Selección manual'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Se prioriza una alternativa sin cierres'),
          findsOneWidget,
        );
        Navigator.of(tester.element(find.text('Por qué esta ruta'))).pop();
        await tester.pumpAndSettle();
        reports.rows = [];
        reports.events.add(null);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 351));
        await tester.pumpAndSettle();
        summary = tester.widget<MobilityRecommendationSummary>(
          find.byType(MobilityRecommendationSummary),
        );
        expect(summary.suggestedIndex, 1);
        expect(summary.selectedIndex, 1);
        expect(find.text('Sin reportes activos próximos'), findsOneWidget);
        expect(routing.calls, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(reports.events.hasListener, isFalse);
        await tester.runAsync(reports.events.close);
      },
    );
  }

  testWidgets(
    'reportes no disponibles no se presentan como ausencia de reportes',
    (tester) async {
      final routing = ControlledRouting();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapSearchPanel(
              currentPosition: const LatLng(7.1, -73.1),
              locationStatus: LocationStatus.coordinatesObtained,
              reportsAvailable: false,
              routingService: routing,
              geocodingService: FixedGeocoding(),
              placeSuggestionService: FixedSuggestions(),
            ),
          ),
        ),
      );
      await calculate(tester, routing);
      expect(find.textContaining('Reportes no disponibles'), findsOneWidget);
      expect(find.text('Sin reportes activos próximos'), findsNothing);
      expect(
        tester
            .widget<MobilityRecommendationSummary>(
              find.byType(MobilityRecommendationSummary),
            )
            .suggestedIndex,
        1,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'recomendaciones tardías no sobrescriben el snapshot más reciente',
    (tester) async {
      final reports = ValueNotifier<List<RoadIncidentReport>>([]);
      final routing = ControlledRouting();
      final engine = PendingIncidentEngine();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<List<RoadIncidentReport>>(
              valueListenable: reports,
              builder: (context, value, _) => MapSearchPanel(
                currentPosition: const LatLng(7.1, -73.1),
                locationStatus: LocationStatus.coordinatesObtained,
                incidentReports: value,
                routingService: routing,
                recommendationEngine: engine,
                geocodingService: FixedGeocoding(),
                placeSuggestionService: FixedSuggestions(),
              ),
            ),
          ),
        ),
      );
      // Calculation awaits an injected engine, so do not pumpAndSettle its spinner.
      await tester.enterText(find.byType(TextField).last, 'Destino');
      await tester.ensureVisible(find.text('Calcular ruta'));
      await tester.tap(find.text('Calcular ruta'));
      await tester.pump();
      routing.pending.complete([firstRoute, secondRoute]);
      await tester.pump();
      await engine.complete(0);
      await tester.pumpAndSettle();
      reports.value = [closureOnSecond()];
      await tester.pump();
      await tester.pump();
      expect(engine.requests.length, 2);
      reports.value = [];
      await tester.pump();
      await tester.pump();
      expect(engine.requests.length, 3);
      await engine.complete(2);
      await tester.pumpAndSettle();
      await engine.complete(1);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MobilityRecommendationSummary>(
              find.byType(MobilityRecommendationSummary),
            )
            .suggestedIndex,
        1,
      );
      expect(
        tester
            .widget<RouteIncidentStatus>(find.byType(RouteIncidentStatus))
            .analysis!
            .total,
        0,
      );
      expect(routing.calls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      reports.dispose();
    },
  );
}
