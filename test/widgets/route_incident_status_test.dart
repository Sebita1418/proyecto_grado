import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/models/incident_report_draft.dart';
import 'package:transporte_inteligente/widgets/route_incident_status.dart';
import 'package:transporte_inteligente/widgets/road_incident_details_sheet.dart';

import '../mobility/route_incident_analysis_test.dart'
    show analyzeIncidents, incident;

void main() {
  testWidgets('categorías a 320 px / 150 %, proximidad y detalle reutilizado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final analysis = analyzeIncidents([
      for (final type in IncidentType.values)
        incident(id: type.name, type: type),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(body: RouteIncidentStatus(analysis: analysis)),
      ),
    );
    expect(find.textContaining('6 reportes activos próximos'), findsOneWidget);
    await tester.tap(find.byType(RouteIncidentStatus));
    await tester.pumpAndSettle();
    expect(find.textContaining('proximidad geométrica'), findsOneWidget);
    expect(find.text('Aproximadamente 0 m del recorrido'), findsWidgets);
    await tester.tap(find.text('Accidente'));
    await tester.pumpAndSettle();
    expect(find.byType(RoadIncidentDetailsSheet), findsOneWidget);
    expect(find.text('Reporte publicado · Activo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
