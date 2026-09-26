import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/widgets/report_incident_sheet.dart';
import 'package:transporte_inteligente/widgets/road_incident_details_sheet.dart';
import 'package:transporte_inteligente/widgets/road_incident_marker.dart';

void main() {
  for (final width in [390.0, 768.0, 1440.0]) {
    testWidgets('categorías y detalle accesibles a $width / altura reducida', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final type in IncidentType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: SizedBox.square(
                    dimension: 48,
                    child: RoadIncidentMarker(
                      type: type,
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => RoadIncidentDetailsSheet(
                            draft: IncidentReportDraft(
                              type: type,
                              description: 'Carril derecho',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.byIcon(type.icon), findsOneWidget);
        expect(
          find.byTooltip('${type.label}: borrador sin publicar'),
          findsOneWidget,
        );
        await tester.tap(find.byType(RoadIncidentMarker));
        await tester.pumpAndSettle();
        expect(find.text(type.label), findsOneWidget);
        expect(find.text('Carril derecho'), findsOneWidget);
        expect(find.text('Borrador sin publicar'), findsOneWidget);
        await tester.tap(find.byTooltip('Cerrar detalle'));
        await tester.pumpAndSettle();
        expect(find.byType(RoadIncidentDetailsSheet), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
