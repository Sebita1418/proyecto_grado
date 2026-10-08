import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/routing/routing_capabilities.dart';
import 'package:transporte_inteligente/services/mode_routing_service.dart';
import 'package:transporte_inteligente/services/osrm_routing_service.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';
import 'package:transporte_inteligente/widgets/travel_mode_selector.dart';
import 'package:transporte_inteligente/widgets/route_result_card.dart';
import 'package:transporte_inteligente/widgets/departure_time_selector.dart';
import 'package:transporte_inteligente/mobility/decision/departure_time_context.dart';
import 'package:transporte_inteligente/theme/mobility_theme.dart';

import '../screens/home/route_flow_test.dart'
    show
        ControlledRouting,
        FixedGeocoding,
        FixedSuggestions,
        firstRoute,
        secondRoute;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'four mode cards, actual evidence states and responsive $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        TransportMode? selected, unavailable;
        final caps = RoutingCapabilities([
          TransportMode.driving,
          TransportMode.walking,
          TransportMode.cycling,
        ]);
        final snapshot = MultimodalMobilitySnapshot([
          const ModeRouteSummary(
            mode: TransportMode.walking,
            availability: ModeAvailability.available,
            reason: 'Route received',
            durationSeconds: 600,
            distanceMeters: 1000,
            provider: 'test',
            alternativeCount: 1,
          ),
          const ModeRouteSummary(
            mode: TransportMode.cycling,
            availability: ModeAvailability.error,
            reason: 'Network error',
            failure: RoutingFailure.networkError,
          ),
        ]);
        await tester.pumpWidget(
          MaterialApp(
            theme: MobilityTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: TravelModeSelector(
                  capabilities: caps,
                  snapshot: snapshot,
                  onModeSelected: (m) => selected = m,
                  onUnavailableModeTap: (m) => unavailable = m,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in [
          'Vehículo',
          'A pie',
          'Bicicleta',
          'Transporte público',
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        expect(
          find.text('Sin consultar: proveedor configurado'),
          findsOneWidget,
        );
        expect(find.textContaining('Disponible · 10 min'), findsOneWidget);
        expect(find.text('Error: Network error'), findsOneWidget);
        await tester.ensureVisible(find.text('A pie'));
        await tester.tap(find.text('A pie'));
        expect(selected, TransportMode.walking);
        await tester.ensureVisible(find.text('Transporte público'));
        await tester.tap(find.text('Transporte público'));
        expect(unavailable, TransportMode.publicTransport);
        expect(selected, TransportMode.walking);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'mode changes use real request, keep endpoints, unsupported/errors preserve route',
    (tester) async {
      final car = ControlledRouting(),
          foot = ControlledRouting(),
          bike = ControlledRouting();
      final provider = ModeRoutingService(
        driving: car,
        walking: foot,
        cycling: bike,
      );
      addTearDown(car.dispose);
      addTearDown(foot.dispose);
      addTearDown(bike.dispose);
      addTearDown(provider.dispose);
      final geo = FixedGeocoding(), suggestions = FixedSuggestions();
      addTearDown(geo.dispose);
      addTearDown(suggestions.dispose);
      final changes = <RouteResult?>[];
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
              onRouteChanged: changes.add,
              onStartNavigation: (_, _) =>
                  fail('Nonvehicle must not start navigation'),
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
      Future<void> select(String label) async {
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pump();
        await tester.pump();
      }

      await select('Transporte público');
      expect(car.calls, 1);
      expect(foot.calls, 0);
      expect(bike.calls, 0);
      expect(changes.last, same(firstRoute));
      await select('A pie');
      expect(foot.calls, 1);
      expect(foot.lastOrigin, firstRoute.origin);
      expect(foot.lastDestination, firstRoute.destination);
      foot.pending.complete([secondRoute]);
      await tester.pumpAndSettle();
      expect(changes.last, same(secondRoute));
      expect(
        tester.widget<RouteResultCard>(find.byType(RouteResultCard)).onStart,
        isNull,
      );
      expect(find.text('RUTA SUGERIDA'), findsNothing);
      expect(
        find.textContaining('Sin recomendación vehicular'),
        findsOneWidget,
      );
      await select('Bicicleta');
      expect(bike.calls, 1);
      expect(bike.lastOrigin, firstRoute.origin);
      bike.pending.completeError(
        const OsrmRoutingException(
          'Network test',
          failure: RoutingFailure.networkError,
        ),
      );
      await tester.pumpAndSettle();
      expect(changes.last, same(secondRoute));
      expect(
        tester.widget<RouteResultCard>(find.byType(RouteResultCard)).route,
        same(secondRoute),
      );
      await select('Bicicleta');
      bike.pending.complete([firstRoute]);
      await tester.pumpAndSettle();
      expect(changes.last, same(firstRoute));
      expect(
        tester.widget<RouteResultCard>(find.byType(RouteResultCard)).onStart,
        isNull,
      );
      expect(car.calls, 1);
    },
  );
  testWidgets('scheduled departure remains explicit and without prediction', (
    tester,
  ) async {
    final departure = DepartureTimeContext.scheduled(DateTime(2027, 1, 2, 12));
    await tester.pumpWidget(
      MaterialApp(
        theme: MobilityTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DepartureTimeSelector(value: departure, onChanged: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Fecha y hora seleccionadas:'), findsOneWidget);
    expect(find.text('Planificación sin predicciones'), findsOneWidget);
    expect(
      find.textContaining('no representa el tráfico futuro'),
      findsOneWidget,
    );
  });
}
