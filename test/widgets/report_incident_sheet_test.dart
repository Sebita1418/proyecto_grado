import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/widgets/report_incident_sheet.dart';

void main() {
  testWidgets(
    'volver al GPS reemplaza la coordenada manual y guarda el borrador',
    (tester) async {
      IncidentReportDraft? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportIncidentSheet(
              currentPosition: const LatLng(7.1, -73.1),
              initialDraft: const IncidentReportDraft(
                type: IncidentType.accident,
                coordinates: LatLng(8, -72),
                manualLocation: true,
                description: 'Descripción conservada',
              ),
              onDraftChanged: (draft) => changed = draft,
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Usar mi ubicación actual'));
      await tester.tap(find.text('Usar mi ubicación actual'));
      await tester.pump();
      expect(changed!.coordinates, const LatLng(7.1, -73.1));
      expect(changed!.manualLocation, isFalse);
      expect(changed!.type, IncidentType.accident);
      expect(changed!.description, 'Descripción conservada');
      expect(find.text('Usar mi ubicación actual'), findsNothing);
    },
  );
  testWidgets(
    'teclado y texto ampliado permiten preparar; descripción limitada a 200',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      IncidentReportDraft? draft;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewInsets: const EdgeInsets.only(bottom: 300),
              textScaler: const TextScaler.linear(1.5),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: ReportIncidentSheet(
              initialDraft: const IncidentReportDraft(
                type: IncidentType.other,
                coordinates: LatLng(7, -73),
              ),
              onSubmit: (value) => draft = value,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'x' * 230);
      await tester.ensureVisible(find.text('Preparar reporte'));
      await tester.tap(find.text('Preparar reporte'));
      await tester.pump();
      expect(draft!.description!.length, 200);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('ReportIncidentSheet muestra encabezado y las seis categorías', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ReportIncidentSheet())),
    );

    expect(find.text('Reportar novedad'), findsOneWidget);
    expect(find.byTooltip('Cerrar'), findsOneWidget);
    expect(find.text('Accidente'), findsOneWidget);
    expect(find.text('Congestión'), findsOneWidget);
    expect(find.text('Obra en la vía'), findsOneWidget);
    expect(find.text('Vía cerrada'), findsOneWidget);
    expect(find.text('Peligro / Obstáculo'), findsOneWidget);
    expect(find.text('Otro'), findsOneWidget);
  });

  testWidgets(
    'botón Preparar reporte bloqueado sin tipo; seleccionar tipo lo habilita y envía draft',
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

      // Verify Preparar reporte is disabled initially
      final submitFinder = find.widgetWithText(
        FilledButton,
        'Preparar reporte',
      );
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
      await tester.ensureVisible(submitFinder);
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
    expect(find.text('Tu ubicación actual'), findsOneWidget);
    expect(find.text('7.12345, -73.12345'), findsOneWidget);

    // Case 2: without GPS position
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ReportIncidentSheet(currentPosition: null)),
      ),
    );
    expect(find.text('Ubicación no disponible'), findsOneWidget);
    expect(
      find.text('Selecciona un punto en el mapa o activa el GPS.'),
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

    await tester.tap(find.text('Cambiar ubicación'));
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
        expect(find.text('Reportar novedad'), findsOneWidget);
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
