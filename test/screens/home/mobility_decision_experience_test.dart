import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/mobility/decision/departure_time_context.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';
import 'package:transporte_inteligente/widgets/mobility_planner/departure_time_selector.dart';
import 'package:transporte_inteligente/widgets/mobility_planner/mobility_planner_section.dart';
import 'package:transporte_inteligente/widgets/mobility_recommendation_summary.dart';
import 'package:transporte_inteligente/widgets/route_result_card.dart';

import 'route_flow_test.dart'
    show
        ControlledRouting,
        FixedGeocoding,
        FixedSuggestions,
        firstRoute,
        secondRoute,
        tapLabel;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'decision flow, schedule and navigation preserve selection at $width',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final routing = ControlledRouting();
        RouteResult? started;
        final changes = <RouteResult?>[];
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: MapSearchPanel(
                currentPosition: const LatLng(7.1, -73.1),
                locationStatus: LocationStatus.coordinatesObtained,
                routingService: routing,
                geocodingService: FixedGeocoding(),
                placeSuggestionService: FixedSuggestions(),
                onRouteChanged: changes.add,
                onStartNavigation: (route, _) => started = route,
              ),
            ),
          ),
        );
        await tester.enterText(find.byType(TextField).last, 'Destino');
        await tester.ensureVisible(find.text('Calcular ruta'));
        await tester.tap(find.text('Calcular ruta'));
        await tester.pump();
        routing.pending.complete([firstRoute, secondRoute]);
        await tester.pumpAndSettle();
        var planner = tester.widget<MobilityPlannerSection>(
          find.byType(MobilityPlannerSection),
        );
        expect(planner.result!.hasRecommendation, isTrue);
        expect(planner.result!.recommendation!.recommended.id, 'osrm-1');
        expect(find.text('Disponible para analizar'), findsOneWidget);
        expect(
          tester.getSize(find.byType(MapSearchPanel)).width,
          lessThanOrEqualTo(560),
        );
        await tapLabel(tester, 'Cambiar alternativa');
        await tapLabel(tester, 'Alternativa 1');
        expect(find.text('Selección manual'), findsOneWidget);
        await tapLabel(tester, '¿Por qué esta ruta?');
        expect(find.text('Análisis de movilidad'), findsOneWidget);
        expect(find.textContaining('Alternativa 2 · 15 min'), findsOneWidget);
        final changeCount = changes.length;
        final future = DateTime.now().add(const Duration(days: 1));
        tester
            .widget<DepartureTimeSelector>(find.byType(DepartureTimeSelector))
            .onChanged(DepartureTimeContext.scheduled(future));
        await tester.pumpAndSettle();
        planner = tester.widget<MobilityPlannerSection>(
          find.byType(MobilityPlannerSection),
        );
        expect(planner.result!.hasRecommendation, isFalse);
        expect(planner.result!.context.departureTime.at, future);
        expect(find.byType(MobilityRecommendationSummary), findsNothing);
        expect(
          find.textContaining('Sin información temporal suficiente.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('duración solo de referencia'),
          findsOneWidget,
        );
        expect(find.text('Iniciar ruta'), findsNothing);
        expect(
          tester.widget<RouteResultCard>(find.byType(RouteResultCard)).route,
          same(firstRoute),
        );
        expect(changes.length, changeCount);
        expect(routing.calls, 1);
        await tapLabel(tester, 'Ahora');
        expect(find.text('Selección manual'), findsOneWidget);
        expect(
          tester
              .widget<MobilityPlannerSection>(
                find.byType(MobilityPlannerSection),
              )
              .result!
              .hasRecommendation,
          isTrue,
        );
        await tapLabel(tester, 'Iniciar ruta');
        expect(started, same(firstRoute));
        expect(routing.calls, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        routing.dispose();
      },
    );
  }

  testWidgets(
    'scheduling before calculation does not request routing or invent a result',
    (tester) async {
      final routing = ControlledRouting();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapSearchPanel(
              currentPosition: const LatLng(7.1, -73.1),
              locationStatus: LocationStatus.coordinatesObtained,
              routingService: routing,
              geocodingService: FixedGeocoding(),
              placeSuggestionService: FixedSuggestions(),
            ),
          ),
        ),
      );
      tester
          .widget<DepartureTimeSelector>(find.byType(DepartureTimeSelector))
          .onChanged(
            DepartureTimeContext.scheduled(
              DateTime.now().add(const Duration(days: 1)),
            ),
          );
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Calcular ruta');
      expect(routing.calls, 0);
      expect(find.byType(RouteResultCard), findsNothing);
      expect(find.byType(MobilityRecommendationSummary), findsNothing);
      expect(find.textContaining('Salida:'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      routing.dispose();
    },
  );
}
