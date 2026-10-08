import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/mobility/analytics/mobility_analytics.dart';
import 'package:transporte_inteligente/mobility/analytics/mobility_analytics_repository.dart';
import 'package:transporte_inteligente/mobility/decision/departure_time_context.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/services/mode_routing_service.dart';
import 'package:transporte_inteligente/widgets/historical_departure_guidance_card.dart';
import 'package:transporte_inteligente/widgets/departure_time_selector.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';
import 'package:transporte_inteligente/widgets/route_result_card.dart';
import 'package:transporte_inteligente/theme/mobility_theme.dart';

import '../mobility/analytics/historical_departure_guidance_test.dart'
    as fixtures;
import '../screens/home/route_flow_test.dart'
    show ControlledRouting, FixedGeocoding, FixedSuggestions, firstRoute;

class ControlledHistoricalRepository implements MobilityAnalyticsRepository {
  bool fail = false;
  AnalyticsBatch value = fixtures.denseBatch();
  Completer<AnalyticsBatch>? pending;
  int calls = 0;
  @override
  Future<AnalyticsBatch> fetch(MobilityAnalyticsQuery query) async {
    calls++;
    if (fail) throw StateError('offline');
    return pending?.future ?? value;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'historical card responsive $width text $scale, source/privacy/disclaimer',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = ControlledHistoricalRepository();
          await tester.pumpWidget(
            MaterialApp(
              theme: MobilityTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: HistoricalDepartureGuidanceCard(
                    departure: fixtures.selected,
                    repository: repo,
                    now: () => fixtures.end,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text('Menor actividad histórica de reportes'),
            findsOneWidget,
          );
          expect(find.textContaining('America/Bogota'), findsOneWidget);
          expect(
            find.textContaining('Días completos comparados:'),
            findsOneWidget,
          );
          expect(find.textContaining('Muestra:'), findsOneWidget);
          expect(
            find.textContaining('sin relación geográfica'),
            findsOneWidget,
          );
          expect(
            find.textContaining('Cero reportes no significa cero tráfico'),
            findsOneWidget,
          );
          await tester.ensureVisible(find.text('Ver franjas observadas'));
          await tester.tap(find.text('Ver franjas observadas'));
          await tester.pumpAndSettle();
          expect(
            find.text('08:00–09:00 · 4 reportes / 4 fechas'),
            findsOneWidget,
          );
          for (var i = 0; i < 8; i++) {
            await tester.drag(
              find.byType(SingleChildScrollView),
              const Offset(0, -250),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          }
          expect(repo.calls, 1);
        },
      );
    }
  }
  testWidgets(
    'loading, error, retry, empty, partial and insufficient retain distinct meanings',
    (tester) async {
      final repo = ControlledHistoricalRepository()
        ..pending = Completer<AnalyticsBatch>();
      await tester.pumpWidget(
        MaterialApp(
          theme: MobilityTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HistoricalDepartureGuidanceCard(
                departure: fixtures.selected,
                repository: repo,
                now: () => fixtures.end,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Cargando historial de reportes…'), findsOneWidget);
      repo.pending!.completeError(StateError('offline'));
      repo.pending = null;
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Datos históricos no disponibles.'),
        findsOneWidget,
      );
      expect(find.textContaining('Muestra:'), findsNothing);
      Future<void> tap(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      repo.value = AnalyticsBatch([], evaluatedAt: fixtures.end);
      await tap('Reintentar');
      expect(
        find.text('Sin reportes registrados en el periodo consultado.'),
        findsOneWidget,
      );
      repo.value = fixtures.denseBatch(truncated: true);
      await tap('Actualizar historial');
      expect(
        find.text('Cobertura parcial: no permite orientar horarios.'),
        findsOneWidget,
      );
      expect(find.text('Menor actividad histórica de reportes'), findsNothing);
      repo.value = AnalyticsBatch([
        fixtures.row(fixtures.query.start),
      ], evaluatedAt: fixtures.end);
      await tap('Actualizar historial');
      expect(
        find.text('Datos insuficientes para orientar horarios'),
        findsWidgets,
      );
      expect(find.text('Menor actividad histórica de reportes'), findsNothing);
      repo.value = fixtures.denseBatch();
      await tap('Actualizar historial');
      expect(
        find.text('Menor actividad histórica de reportes'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'latest scheduled date while loading updates cached result without another query',
    (tester) async {
      final repo = ControlledHistoricalRepository()
        ..pending = Completer<AnalyticsBatch>();
      Widget screen(DateTime departure) => MaterialApp(
        theme: MobilityTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: HistoricalDepartureGuidanceCard(
              departure: departure,
              repository: repo,
              now: () => fixtures.end,
            ),
          ),
        ),
      );
      await tester.pumpWidget(screen(fixtures.selected));
      await tester.pumpWidget(
        screen(fixtures.selected.add(const Duration(days: 1))),
      );
      repo.pending!.complete(fixtures.denseBatch());
      repo.pending = null;
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Comparación histórica: jueves'),
        findsOneWidget,
      );
      await tester.pumpWidget(screen(fixtures.selected));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Comparación histórica: miércoles'),
        findsOneWidget,
      );
      expect(repo.calls, 1);
    },
  );
  testWidgets(
    'Programar preserves selection/route and orientation makes zero routing or navigation calls',
    (tester) async {
      final car = ControlledRouting(),
          foot = ControlledRouting(),
          bike = ControlledRouting();
      final provider = ModeRoutingService(
        driving: car,
        walking: foot,
        cycling: bike,
      );
      final geo = FixedGeocoding(), suggestions = FixedSuggestions();
      addTearDown(car.dispose);
      addTearDown(foot.dispose);
      addTearDown(bike.dispose);
      addTearDown(provider.dispose);
      addTearDown(geo.dispose);
      addTearDown(suggestions.dispose);
      final history = ControlledHistoricalRepository()..fail = true;
      final changes = <RouteResult?>[];
      var starts = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: MobilityTheme.light,
          home: Scaffold(
            body: MapSearchPanel(
              currentPosition: firstRoute.origin,
              locationStatus: LocationStatus.coordinatesObtained,
              routingService: car,
              modeRoutingService: provider,
              geocodingService: geo,
              placeSuggestionService: suggestions,
              analyticsRepository: history,
              onRouteChanged: changes.add,
              onStartNavigation: (_, _) => starts++,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, 'Destino');
      await tester.ensureVisible(find.text('Analizar rutas'));
      await tester.tap(find.text('Analizar rutas'));
      await tester.pump();
      car.pending.complete([firstRoute]);
      await tester.pumpAndSettle();
      final changeCount = changes.length;
      final departure = fixtures.selected;
      tester
          .widget<DepartureTimeSelector>(find.byType(DepartureTimeSelector))
          .onChanged(DepartureTimeContext.scheduled(departure));
      await tester.pumpAndSettle();
      expect(history.calls, 1);
      expect(find.byType(HistoricalDepartureGuidanceCard), findsOneWidget);
      expect(
        tester.widget<RouteResultCard>(find.byType(RouteResultCard)).route,
        same(firstRoute),
      );
      expect(
        tester
            .widget<RouteResultCard>(find.byType(RouteResultCard))
            .referenceOnly,
        isTrue,
      );
      history.fail = false;
      history.value = AnalyticsBatch([], evaluatedAt: DateTime.now().toUtc());
      final retry = find.descendant(
        of: find.byType(HistoricalDepartureGuidanceCard),
        matching: find.text('Reintentar'),
      );
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DepartureTimeSelector>(find.byType(DepartureTimeSelector))
            .value
            .at,
        departure,
      );
      expect(car.calls, 1);
      expect(foot.calls, 0);
      expect(bike.calls, 0);
      expect(starts, 0);
      expect(changes.length, changeCount);
      tester
          .widget<DepartureTimeSelector>(find.byType(DepartureTimeSelector))
          .onChanged(DepartureTimeContext.now(fixtures.end));
      await tester.pumpAndSettle();
      expect(find.byType(HistoricalDepartureGuidanceCard), findsNothing);
      expect(history.calls, 2);
      expect(car.calls, 1);
      expect(changes.length, changeCount);
      expect(tester.takeException(), isNull);
    },
  );
}
