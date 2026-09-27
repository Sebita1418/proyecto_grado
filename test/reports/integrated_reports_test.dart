import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/controllers/road_incident_controller.dart';
import 'package:transporte_inteligente/models/road_incident_report.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/widgets/report_incident_sheet.dart';
import 'package:transporte_inteligente/widgets/road_incident_marker.dart';
import 'package:transporte_inteligente/widgets/road_incident_reports_sheet.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';

import '../screens/home/route_flow_test.dart' show FixedLocation, tapLabel;
import 'road_incident_test.dart' show FakeRoadIncidents, reportRow;

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('lista realtime conserva una suscripción y reintenta a $width / 150%', (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeRoadIncidents()..fail = true;
      final controller = RoadIncidentController(service);
      await controller.refresh();
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)), child: child!),
        home: Scaffold(body: Center(child: SizedBox(width: 560, height: 650, child: RoadIncidentReportsSheet(controller: controller, onCreate: () {})))),
      ));
      expect(find.textContaining('No fue posible cargar'), findsOneWidget);
      service.fail = false;
      await tester.tap(find.byTooltip('Actualizar reportes'));
      await tester.pumpAndSettle();
      expect(find.text('No hay reportes activos disponibles.'), findsOneWidget);
      expect(service.events.hasListener, isTrue);
      service.rows = [RoadIncidentReport.fromMap(reportRow()), RoadIncidentReport.fromMap(reportRow())];
      service.events.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Carril derecho'), findsOneWidget);
      expect(controller.reports, hasLength(1));
      service.events.addError(StateError('disconnected'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Actualización en vivo no disponible'), findsOneWidget);
      expect(find.text('Carril derecho'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      expect(service.events.hasListener, isFalse);
      await tester.runAsync(service.events.close);
    });
  }

  testWidgets('preview, editar, publicar y realtime dejan un solo marcador y limpian borrador', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FakeRoadIncidents();
    await tester.pumpWidget(MaterialApp(home: HomeScreen(
      roadIncidentService: service,
      locationService: FixedLocation(),
      loadProfile: () async => null,
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Reportar novedad vial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accidente'));
    await tester.enterText(find.byType(TextField), 'Carril derecho');
    await tapLabel(tester, 'Vista previa en mapa');
    expect(service.creates, 0);
    expect(tester.widget<RoadIncidentMarker>(find.byType(RoadIncidentMarker)).published, isFalse);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(RoadIncidentMarker));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Editar borrador');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Carril derecho');
    await tapLabel(tester, 'Publicar reporte');
    expect(service.creates, 1);
    expect(find.text('Reporte publicado correctamente.'), findsOneWidget);
    expect(tester.widget<RouteMap>(find.byType(RouteMap)).overlayMarkers, hasLength(1));
    expect(tester.widget<RoadIncidentMarker>(find.byType(RoadIncidentMarker)).published, isTrue);
    service.events.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(tester.widget<RouteMap>(find.byType(RouteMap)).overlayMarkers, hasLength(1));
    await tester.tap(find.byTooltip('Reportar novedad vial'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Publicar reporte')).onPressed, isNull);
    await tapLabel(tester, 'Descartar borrador');
    expect(find.byType(ReportIncidentSheet), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(service.events.close);
  });
}
