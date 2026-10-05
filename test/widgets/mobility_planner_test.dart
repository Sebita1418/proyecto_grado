import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/mobility/decision/departure_time_context.dart';
import 'package:transporte_inteligente/widgets/mobility_planner/departure_time_selector.dart';
import 'package:transporte_inteligente/widgets/mobility_planner/mobility_planner_section.dart';

void main() {
  testWidgets('rechaza hora pasada del día actual sin cambiar la salida', (
    tester,
  ) async {
    final departure = DepartureTimeContext.now(DateTime.now());
    DepartureTimeContext? changed;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
        home: Scaffold(
          body: DepartureTimeSelector(
            value: departure,
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Programar salida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().day}').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '00');
    await tester.enterText(find.byType(TextField).last, '00');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(changed, isNull);
    expect(find.text('Elige una fecha y hora futuras.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'planificador $width con texto 1.5, estados y controles accesibles',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var departure = DepartureTimeContext.now(DateTime.now());
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: StatefulBuilder(
                        builder: (context, setState) => MobilityPlannerSection(
                          departure: departure,
                          onDepartureChanged: (value) =>
                              setState(() => departure = value),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(
          tester.getSemantics(find.text('Ahora')).label,
          contains('Ahora'),
        );
        expect(find.text('Vehículo'), findsOneWidget);
        expect(find.text('Información insuficiente'), findsOneWidget);
        await tester.ensureVisible(find.text('Otros medios'));
        await tester.tap(find.text('Otros medios'));
        await tester.pumpAndSettle();
        expect(find.text('A pie'), findsOneWidget);
        expect(find.text('Bicicleta'), findsOneWidget);
        expect(find.text('Transporte público'), findsOneWidget);
        expect(
          find.text('Información de ruta no disponible'),
          findsNWidgets(2),
        );
        expect(find.text('Datos de transporte no integrados'), findsOneWidget);
        expect(find.text('Todavía no soportado'), findsNWidgets(3));
        expect(find.textContaining(' min'), findsNothing);
        expect(find.textContaining('Predicción'), findsNothing);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets('programa con controles reales y vuelve a Ahora', (tester) async {
    var departure = DepartureTimeContext.now(DateTime.now());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: MobilityPlannerSection(
                departure: departure,
                onDepartureChanged: (value) =>
                    setState(() => departure = value),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Programar salida'));
    await tester.pumpAndSettle();
    final picker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(picker.firstDate, DateUtils.dateOnly(DateTime.now()));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(departure.isScheduled, isTrue);
    expect(departure.at.isAfter(DateTime.now()), isTrue);
    expect(find.textContaining('Salida:'), findsOneWidget);
    expect(
      find.textContaining('Sin información temporal suficiente.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ahora'));
    await tester.pumpAndSettle();
    expect(departure.isNow, isTrue);
    expect(find.textContaining('Salida:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar selector conserva salida programada', (tester) async {
    final departure = DepartureTimeContext.scheduled(
      DateTime.now().add(const Duration(days: 2)),
    );
    DepartureTimeContext? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DepartureTimeSelector(
            value: departure,
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Programar salida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(changed, isNull);
    expect(find.textContaining('Salida:'), findsOneWidget);
  });
}
