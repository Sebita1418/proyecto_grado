import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/models/perfil_model.dart';
import 'package:transporte_inteligente/services/location_service.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/mobility/validation/mobility_validation.dart';
import 'package:transporte_inteligente/mobility/decision/departure_time_context.dart';
import 'package:transporte_inteligente/navigation/navigation_session.dart';
import 'package:transporte_inteligente/screens/home/home_screen.dart';
import 'package:transporte_inteligente/screens/login/login_screen.dart';
import 'package:transporte_inteligente/screens/perfil/perfil_screen.dart';
import 'package:transporte_inteligente/screens/analytics/mobility_analytics_screen.dart';
import 'package:transporte_inteligente/screens/validation/mobility_validation_screen.dart';
import 'package:transporte_inteligente/widgets/map_search_panel.dart';
import 'package:transporte_inteligente/widgets/departure_time_selector.dart';
import 'package:transporte_inteligente/widgets/historical_departure_guidance_card.dart';
import 'package:transporte_inteligente/widgets/mobility_recommendation_summary.dart';
import 'package:transporte_inteligente/widgets/route_result_card.dart';
import 'package:transporte_inteligente/widgets/route_alternatives_selector.dart';
import 'package:transporte_inteligente/widgets/report_incident_sheet.dart';
import 'package:transporte_inteligente/widgets/navigation_status_card.dart';
import 'package:transporte_inteligente/theme/mobility_theme.dart';

import '../screens/home/route_flow_test.dart'
    show
        ControlledRouting,
        FixedLocation,
        FixedGeocoding,
        FixedSuggestions,
        firstRoute;
import '../reports/road_incident_test.dart' show FakeRoadIncidents;
import '../mobility/validation/mobility_validation_test.dart' as validation;
import '../mobility/analytics/mobility_analytics_test.dart'
    show FakeRepository, batch, observation;
import '../widgets/historical_departure_guidance_test.dart'
    show ControlledHistoricalRepository;
import '../mobility/analytics/historical_departure_guidance_test.dart'
    as historical;
import '../navigation/navigation_v2_test.dart' show V2Gps, v2Route;

class VisualScene {
  const VisualScene(this.widget, this.dispose, {this.prepare});
  final Widget widget;
  final Future<void> Function() dispose;
  final Future<void> Function(WidgetTester)? prepare;
}

Future<VisualScene> scene(String name) async {
  Widget scroll(List<Widget> children) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
  switch (name) {
    case 'login':
      return VisualScene(const LoginScreen(), () async {});
    case 'drawer':
    case 'home':
      final reports = FakeRoadIncidents();
      final location = FixedLocation();
      final routing = ControlledRouting();
      final geocoding = FixedGeocoding();
      final suggestions = FixedSuggestions();
      return VisualScene(
        HomeScreen(
          locationService: location,
          routingService: routing,
          geocodingService: geocoding,
          placeSuggestionService: suggestions,
          roadIncidentService: reports,
          loadProfile: () async => Perfil(
            id: 'fixture',
            nombre: 'Usuario de prueba',
            correo: 'fixture@example.test',
            rol: 'usuario',
            activo: true,
          ),
        ),
        () async {
          await reports.events.close();
          routing.dispose();
          geocoding.dispose();
          suggestions.dispose();
        },
        prepare: name == 'drawer'
            ? (tester) async {
                await tester.tap(find.byTooltip('Abrir menú de navegación'));
                await tester.pumpAndSettle();
              }
            : null,
      );
    case 'profile':
      return VisualScene(
        PerfilScreen(
          perfil: Perfil(
            id: 'fixture',
            nombre: 'Usuario de prueba',
            correo: 'fixture@example.test',
            rol: 'usuario',
            activo: true,
          ),
          locationStatus: LocationStatus.coordinatesObtained,
          authenticated: true,
          provider: 'google',
          onSignOut: () {},
        ),
        () async {},
      );
    case 'planner':
      final routing = ControlledRouting();
      final geocoding = FixedGeocoding();
      final suggestions = FixedSuggestions();
      return VisualScene(
        Scaffold(
          body: SafeArea(
            child: Center(
              child: MapSearchPanel(
                currentPosition: firstRoute.origin,
                locationStatus: LocationStatus.coordinatesObtained,
                routingService: routing,
                geocodingService: geocoding,
                placeSuggestionService: suggestions,
                maxHeight: 900,
              ),
            ),
          ),
        ),
        () async {
          routing.dispose();
          geocoding.dispose();
          suggestions.dispose();
        },
      );
    case 'result':
      final options = [
        validation.option('a', 100, 1000),
        validation.option('b', 120, 800),
      ];
      final recommendation = await VehicleRecommendationEngine(
        clock: () => validation.instant,
      ).recommend(validation.context(), options);
      return VisualScene(
        scroll([
          MobilityRecommendationSummary(
            recommendation: recommendation,
            suggestedIndex: 0,
            selectedIndex: 1,
            manuallySelected: true,
            usesDefaultModes: false,
            compact: true,
          ),
          RouteResultCard(
            route: options[1].route,
            originLabel: 'Origen de prueba',
            destinationLabel: 'Destino de prueba',
            onModify: () {},
            onStart: () {},
          ),
          RouteAlternativesSelector(
            alternatives: options.map((o) => o.route).toList(),
            selectedIndex: 1,
            onSelected: (_) {},
            suggestedIndex: 0,
            manuallySelected: true,
          ),
        ]),
        () async {},
      );
    case 'schedule':
      return VisualScene(
        scroll([
          DepartureTimeSelector(
            value: DepartureTimeContext.scheduled(historical.selected),
            onChanged: (_) {},
          ),
          HistoricalDepartureGuidanceCard(
            departure: historical.selected,
            repository: ControlledHistoricalRepository(),
            now: () => historical.end,
          ),
        ]),
        () async {},
      );
    case 'reports':
      return VisualScene(
        Scaffold(
          body: ReportIncidentSheet(
            initialDraft: IncidentReportDraft(
              type: IncidentType.accident,
              coordinates: firstRoute.origin,
            ),
            onSubmit: (_) {},
          ),
        ),
        () async {},
      );
    case 'navigation':
      final gps = V2Gps();
      final session = NavigationSession(gps)
        ..start(v2Route, 'Destino de prueba');
      return VisualScene(
        scroll([
          NavigationManeuverCard(session: session),
          const SizedBox(height: 12),
          NavigationStatusCard(session: session),
        ]),
        () async {
          session.dispose();
          await gps.updates.close();
        },
      );
    case 'analytics':
      return VisualScene(
        MobilityAnalyticsScreen(
          repository: FakeRepository()
            ..value = batch([observation(), observation()]),
          now: () => DateTime.utc(2026, 10, 6, 12),
        ),
        () async {},
      );
    case 'validation':
      final snapshot = await validation.evaluate(
        [validation.option('a', 100, 1000), validation.option('b', 120, 800)],
        validation.context(
          analyses: [
            validation.analysis('a', 1, closures: 1),
            validation.analysis('b', 0),
          ],
        ),
        selected: 'a',
        manual: true,
      );
      return VisualScene(
        MobilityValidationScreen(snapshot: snapshot),
        () async {},
      );
    default:
      throw ArgumentError(name);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fontRoot = Platform.environment['TI_VISUAL_FONT_ROOT'];
    if (fontRoot != null) {
      final textFonts = FontLoader('Roboto');
      for (final file in [
        'roboto-regular.ttf',
        'roboto-medium.ttf',
        'roboto-bold.ttf',
      ]) {
        textFonts.addFont(
          File('$fontRoot/$file')
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      }
      await textFonts.load();
      await (FontLoader('MaterialIcons')..addFont(
            File('$fontRoot/materialicons-regular.otf')
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes)),
          ))
          .load();
    }
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.test',
      publishableKey: 'fixture-only',
      httpClient: MockClient(
        (_) async => http.Response('{"message":"fixture"}', 400),
      ),
    );
  });
  final names = [
    'login',
    'home',
    'planner',
    'result',
    'schedule',
    'reports',
    'navigation',
    'analytics',
    'validation',
    'profile',
    'drawer',
  ];
  for (final name in names) {
    for (final width in [320.0, 390.0, 768.0, 1440.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$name visual matrix $width text $scale', (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final item = await scene(name);
          final captureKey = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: captureKey,
              child: MaterialApp(
                theme: MobilityTheme.light,
                debugShowCheckedModeBanner: false,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: item.widget,
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (item.prepare != null) await item.prepare!(tester);
          expect(tester.takeException(), isNull);
          final phase = Platform.environment['TI_VISUAL_PHASE'];
          if (phase != null &&
              ((width == 390 && scale == 1) ||
                  (phase != 'before' &&
                      ((width == 320 && scale == 2) ||
                          (width == 1440 && scale == 1))))) {
            await tester.runAsync(() async {
              final boundary =
                  captureKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 1);
              final png = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final folder = Directory('artifacts/figma-final-fidelity/$phase');
              await folder.create(recursive: true);
              await File(
                '${folder.path}/$name-${width.toInt()}-${scale.toInt()}.png',
              ).writeAsBytes(png!.buffer.asUint8List());
              image.dispose();
            });
          }
          if (name != 'home' &&
              name != 'drawer' &&
              name != 'login' &&
              name != 'planner') {
            final scrollable = find.byType(Scrollable).first;
            for (var i = 0; i < 12; i++) {
              await tester.drag(scrollable, const Offset(0, -250));
              await tester.pump();
              expect(tester.takeException(), isNull);
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await item.dispose();
        });
      }
    }
  }
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets(
      'login actions and report submit remain reachable with keyboard/text 2x at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Widget frame(Widget page) => MaterialApp(
          theme: MobilityTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 300),
            ),
            child: child!,
          ),
          home: page,
        );
        await tester.pumpWidget(frame(const LoginScreen()));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).first,
          'fixture@example.test',
        );
        await tester.enterText(find.byType(TextField).last, 'fixture-password');
        await tester.ensureVisible(find.byTooltip('Mostrar contraseña'));
        await tester.tap(find.byTooltip('Mostrar contraseña'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField).last).obscureText,
          isFalse,
        );
        await tester.ensureVisible(find.text('INICIAR SESIÓN'));
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('No fue posible iniciar sesión'),
          findsOneWidget,
        );
        expect(find.byType(HomeScreen), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        IncidentReportDraft? submitted;
        await tester.pumpWidget(
          frame(
            Scaffold(
              body: ReportIncidentSheet(
                initialDraft: IncidentReportDraft(
                  type: IncidentType.accident,
                  coordinates: firstRoute.origin,
                ),
                onSubmit: (draft) => submitted = draft,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Descripción de prueba');
        await tester.ensureVisible(find.text('Preparar reporte'));
        await tester.tap(find.text('Preparar reporte'));
        await tester.pumpAndSettle();
        expect(submitted!.description, 'Descripción de prueba');
        expect(submitted!.type, IncidentType.accident);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'PASS FAIL UNKNOWN NOT_APPLICABLE keep explicit text in styled criteria',
    (tester) async {
      final options = [
        validation.option('a', 100, 1000),
        validation.option('b', 120, 800),
      ];
      final trip = validation.context();
      final decision = await VehicleRecommendationEngine(
        clock: () => validation.instant,
      ).recommend(trip, options);
      final snapshot = const MobilityValidationEvaluator().evaluate(
        validation.project(trip, options, decision, marked: 'b'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: MobilityTheme.light,
          home: MobilityValidationScreen(snapshot: snapshot),
        ),
      );
      await tester.pumpAndSettle();
      for (final text in [
        '✓ Cumple ·',
        '× No cumple ·',
        '! No evaluable ·',
        '— No aplica ·',
      ]) {
        expect(find.textContaining(text), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
