import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/controllers/road_incident_controller.dart';
import 'package:transporte_inteligente/models/road_incident_report.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/widgets/road_incident_reports_sheet.dart';

import '../navigation/navigation_session_test.dart' show route;
import 'road_incident_test.dart' show FakeRoadIncidents, reportRow;

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('filtro geométrico local con realtime a $width / 150%', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeRoadIncidents();
      RoadIncidentReport row(String id, double latitude, String description) =>
          RoadIncidentReport.fromMap({
            ...reportRow(id: id),
            'latitud': latitude,
            'longitud': .01,
            'descripcion': description,
          });
      service.rows = [
        row('near', .0005, 'Novedad cercana'),
        row('far', .02, 'Novedad lejana'),
      ];
      final controller = RoadIncidentController(service);
      final activeRoute = ValueNotifier<RouteResult?>(route);
      await controller.refresh();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                  maxHeight: 700,
                ),
                child: RoadIncidentReportsSheet(
                  controller: controller,
                  activeRoute: activeRoute,
                  onCreate: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Cerca de mi ruta'));
      await tester.pumpAndSettle();
      expect(find.text('Novedad cercana'), findsOneWidget);
      expect(find.text('Novedad lejana'), findsNothing);
      expect(service.fetches, 1);
      service.rows = [row('far', .02, 'Novedad lejana')];
      service.events.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        find.text('No hay novedades cerca de tu ruta con estos filtros.'),
        findsOneWidget,
      );
      activeRoute.value = null;
      await tester.pumpAndSettle();
      expect(find.text('Novedad lejana'), findsOneWidget);
      expect(find.text('Cerca de mi ruta'), findsNothing);
      expect(service.fetches, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      activeRoute.dispose();
      expect(service.events.hasListener, isFalse);
      await tester.runAsync(service.events.close);
    });
  }
}
