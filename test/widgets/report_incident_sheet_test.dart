import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/widgets/report_incident_sheet.dart';

void main() {
  testWidgets('ReportIncidentSheet muestra encabezado y las seis categorías', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ReportIncidentSheet())),
    );

    expect(find.text('Reportar novedad vial'), findsOneWidget);
    expect(find.byTooltip('Cerrar'), findsOneWidget);
    expect(find.text('Accidente'), findsOneWidget);
    expect(find.text('Congestión'), findsOneWidget);
    expect(find.text('Obra en la vía'), findsOneWidget);
    expect(find.text('Vía cerrada'), findsOneWidget);
    expect(find.text('Peligro / Obstáculo'), findsOneWidget);
    expect(find.text('Otro'), findsOneWidget);
  });

  testWidgets(
    'botón Enviar reporte bloqueado sin tipo; seleccionar tipo lo habilita y envía draft',
    (tester) async {
      IncidentReportDraft? submitted;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportIncidentSheet(
              currentPosition: const LatLng(7.12345, -73.12345),
              onSubmit: (draft) => submitted = draft,
            ),
          ),
        ),
      );

      // Verify Enviar reporte is disabled initially
      final submitFinder = find.widgetWithText(FilledButton, 'Enviar reporte');
      expect(tester.widget<FilledButton>(submitFinder).onPressed, isNull);

      // Select 'Accidente'
      await tester.tap(find.text('Accidente'));
      await tester.pump();
      expect(tester.widget<FilledButton>(submitFinder).onPressed, isNotNull);

      // Enter optional description
      await tester.enterText(
        find.byType(TextField),
        'Choque de dos vehículos en carril izquierdo',
      );
      await tester.pump();

      // Submit
      await tester.tap(submitFinder);
      await tester.pump();

      expect(submitted, isNotNull);
      expect(submitted!.type, IncidentType.accident);
      expect(submitted!.coordinates, const LatLng(7.12345, -73.12345));
      expect(
        submitted!.description,
        'Choque de dos vehículos en carril izquierdo',
      );
    },
  );

  testWidgets('ubicación informa coordenadas o ausencia de GPS sin mentir', (
    tester,
  ) async {
    // Case 1: with GPS position
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReportIncidentSheet(
            currentPosition: LatLng(7.12345, -73.12345),
          ),
        ),
      ),
    );
    expect(find.text('Ubicación actual detectada'), findsOneWidget);
    expect(find.text('7.12345, -73.12345'), findsOneWidget);

    // Case 2: without GPS position
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ReportIncidentSheet(currentPosition: null)),
      ),
    );
    expect(find.text('Ubicación no disponible'), findsOneWidget);
    expect(
      find.text('Activa el GPS para asociar coordenadas exactas.'),
      findsOneWidget,
    );
  });

  testWidgets('botón Cambiar ubicación ejecuta callback preparado', (
    tester,
  ) async {
    var locationChangeTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportIncidentSheet(
            onChangeLocation: () => locationChangeTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cambiar'));
    await tester.pump();
    expect(locationChangeTapped, isTrue);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'ReportIncidentSheet es responsive y accesible a ${width.toInt()} px con texto 1.5x',
      (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: const Scaffold(
              body: ReportIncidentSheet(currentPosition: LatLng(7.12, -73.12)),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Reportar novedad vial'), findsOneWidget);
        expect(find.byTooltip('Cerrar'), findsOneWidget);
        expect(
          tester.getSemantics(find.text('Accidente')).label,
          contains('Accidente'),
        );

        semantics.dispose();
      },
    );
  }
}
