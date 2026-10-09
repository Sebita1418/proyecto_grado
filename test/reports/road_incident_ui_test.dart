import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/models/road_incident_report.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/widgets/report_incident_sheet.dart';
import 'package:transporte_inteligente/widgets/road_incident_marker.dart';
import 'package:transporte_inteligente/widgets/road_incident_details_sheet.dart';
import 'package:transporte_inteligente/widgets/route_map.dart';

import '../screens/home/route_flow_test.dart' show FixedLocation;
import 'road_incident_test.dart' show FakeRoadIncidents, reportRow;

void main() {
  testWidgets(
    'publicar bloquea doble tap y conserva datos ante error; reintenta',
    (tester) async {
      var calls = 0;
      var pending = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ReportIncidentSheet(
                    currentPosition: const LatLng(7.1, -73.1),
                    onPublish: (draft) {
                      calls++;
                      expect(draft.description, 'Carril derecho');
                      return pending.future;
                    },
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accidente'));
      await tester.enterText(find.byType(TextField), 'Carril derecho');
      await tester.ensureVisible(find.text('Enviar reporte'));
      await tester.tap(find.text('Enviar reporte'));
      await tester.tap(find.text('Enviar reporte'));
      await tester.pump();
      expect(calls, 1);
      expect(find.text('Enviando reporte…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(
        find.text('No fue posible publicar el reporte. Intenta nuevamente.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Carril derecho',
      );
      expect(find.byType(ReportIncidentSheet), findsOneWidget);
      pending = Completer<void>();
      await tester.ensureVisible(find.text('Enviar reporte'));
      await tester.tap(find.text('Enviar reporte'));
      await tester.pump();
      pending.complete();
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.byType(ReportIncidentSheet), findsNothing);
    },
  );

  testWidgets(
    'Home muestra reporte remoto, detalle privado y refresh sin duplicados',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeRoadIncidents()
        ..rows = [RoadIncidentReport.fromMap(reportRow())];
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            initiallyCollapsed: false,
            roadIncidentService: service,
            locationService: FixedLocation(),
            loadProfile: () async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.fetches, 1);
      expect(
        tester.widget<RouteMap>(find.byType(RouteMap)).overlayMarkers.length,
        1,
      );
      expect(
        tester
            .widget<RoadIncidentMarker>(find.byType(RoadIncidentMarker))
            .published,
        isTrue,
      );
      await tester.tap(find.byType(RoadIncidentMarker));
      await tester.pumpAndSettle();
      expect(find.byType(RoadIncidentDetailsSheet), findsOneWidget);
      expect(find.text('Reporte publicado · Activo'), findsOneWidget);
      expect(find.textContaining('Publicado el'), findsOneWidget);
      expect(find.text('Carril derecho'), findsOneWidget);
      expect(find.textContaining('private-user-id'), findsNothing);
      expect(find.textContaining('report-id'), findsNothing);
      expect(find.text('Borrador sin publicar'), findsNothing);
      await tester.tap(find.byTooltip('Cerrar detalle'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('road-reports-control')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Actualizar reportes'));
      await tester.pumpAndSettle();
      expect(service.fetches, 2);
      await tester.tap(find.byTooltip('Cerrar reportes'));
      await tester.pumpAndSettle();
      expect(find.byType(RoadIncidentMarker), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(service.events.hasListener, isFalse);
      await tester.runAsync(service.events.close);
    },
  );
}
