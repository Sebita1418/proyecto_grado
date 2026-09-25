import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/widgets/mobility_recommendation_summary.dart';

void main() {
  Future<void> render(
    WidgetTester tester, {
    bool manual = false,
    int selected = 1,
    bool defaults = false,
  }) async {
    const origin = LatLng(7.1, -73.1);
    const destination = LatLng(7.2, -73.2);
    final result = await VehicleRecommendationEngine().recommend(
      MobilityContext(
        origin: origin,
        destination: destination,
        allowedModes: {TransportMode.driving},
        requestedAt: DateTime.utc(2026),
      ),
      [
        RouteOption.fromRouteResult(
          id: 'one',
          mode: TransportMode.driving,
          route: const RouteResult(
            origin: origin,
            destination: destination,
            points: [origin, destination],
            distanceMeters: 1000,
            durationSeconds: 120,
          ),
        ),
      ],
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
              recommendation: result,
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
