import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transporte_inteligente/mobility/analytics/mobility_analytics.dart';
import 'package:transporte_inteligente/mobility/analytics/mobility_analytics_repository.dart';
import 'package:transporte_inteligente/controllers/mobility_analytics_controller.dart';
import 'package:transporte_inteligente/services/supabase_mobility_analytics_repository.dart';
import 'package:transporte_inteligente/screens/analytics/mobility_analytics_screen.dart';
import 'package:transporte_inteligente/theme/mobility_theme.dart';
import 'package:transporte_inteligente/models/incident_report_draft.dart';
import 'package:transporte_inteligente/widgets/app_navigation_drawer.dart';

final now = DateTime.utc(2026, 10, 6, 12);
AnalyticsObservation observation({
  String category = 'accident',
  DateTime? at,
  DateTime? expiry,
  String status = 'activo',
}) => AnalyticsObservation(
  category: category,
  createdAt: at ?? now.subtract(const Duration(hours: 2)),
  expiresAt: expiry ?? now.add(const Duration(hours: 1)),
  status: status,
);
AnalyticsBatch batch([List<AnalyticsObservation> rows = const []]) =>
    AnalyticsBatch(rows, evaluatedAt: now);

class FakeRepository implements MobilityAnalyticsRepository {
  AnalyticsBatch value = batch();
  bool fail = false;
  Completer<AnalyticsBatch>? pending;
  final queries = <MobilityAnalyticsQuery>[];
  @override
  Future<AnalyticsBatch> fetch(MobilityAnalyticsQuery query) async {
    queries.add(query);
    if (fail) throw StateError('offline');
    return pending?.future ?? value;
  }
}

void main() {
  final query = MobilityAnalyticsQuery.forPeriod(
    MobilityAnalyticsPeriod.day,
    now,
  );
  const engine = MobilityAnalyticsEngine();
  test('empty, one observation, immutable and actual category vocabulary', () {
    expect(
      analyticsCategories.keys.toSet(),
      IncidentType.values.map((v) => v.databaseValue).toSet(),
    );
    final empty = engine.aggregate(query, batch());
    expect(empty.availability, AnalyticsAvailability.empty);
    expect(empty.peakActivity, isEmpty);
    final one = engine.aggregate(query, batch([observation()]));
    expect(one.total, 1);
    expect(one.active, 1);
    expect(one.predominantCategory, isNull);
    expect(() => one.categories['accident'] = 9, throwsUnsupportedError);
    expect(() => one.temporal.clear(), throwsUnsupportedError);
  });
  test(
    'categories, predominant, ties, peak, order independence and determinism',
    () {
      final rows = [
        observation(),
        observation(),
        observation(
          category: 'hazard',
          at: now.subtract(const Duration(hours: 3)),
        ),
      ];
      final a = engine.aggregate(query, batch(rows));
      final b = engine.aggregate(query, batch(rows.reversed.toList()));
      expect(a.predominantCategory, 'accident');
      expect(a.categories, b.categories);
      expect(a.temporal.map((b) => b.count), b.temporal.map((b) => b.count));
      expect(a.peakActivity.single.count, 2);
      final tie = engine.aggregate(query, batch([rows.first, rows.last]));
      expect(tie.predominantCategory, isNull);
      expect(tie.peakActivity.length, 2);
    },
  );
  test('half-open exact boundaries and hourly/daily grouping', () {
    final s = engine.aggregate(
      query,
      batch([
        observation(at: query.start),
        observation(at: query.end),
        observation(at: query.start.subtract(const Duration(microseconds: 1))),
        observation(at: query.start.add(const Duration(hours: 1))),
      ]),
    );
    expect(s.total, 2);
    expect(s.temporal.length, 24);
    expect(s.temporal.take(2).map((b) => b.count), [1, 1]);
    for (final period in MobilityAnalyticsPeriod.values.skip(1)) {
      final q = MobilityAnalyticsQuery.forPeriod(period, now);
      expect(
        engine.aggregate(q, batch()).temporal.length,
        period.duration.inDays,
      );
    }
    expect(() => MobilityAnalyticsQuery(now, now), throwsArgumentError);
    expect(
      () => MobilityAnalyticsQuery(now.subtract(const Duration(days: 31)), now),
      throwsArgumentError,
    );
  });
  test(
    'server evaluation, expiry equality, cancelled and timezone mapping',
    () {
      final s = engine.aggregate(
        query,
        batch([
          observation(),
          observation(expiry: now),
          observation(status: 'cancelado'),
        ]),
      );
      expect([s.active, s.expired, s.cancelled], [1, 1, 1]);
      final o = AnalyticsObservation.fromMap({
        'tipo': 'other',
        'estado': 'activo',
        'creado_en': '2026-10-06T05:00:00-05:00',
        'expira_en': '2026-10-06T14:00:00Z',
      });
      expect(o.createdAt, DateTime.utc(2026, 10, 6, 10));
      expect(o.createdAt.isUtc, isTrue);
      expect(
        () => parseAnalyticsTimestamp('2026-10-06T10:00:00'),
        throwsFormatException,
      );
    },
  );
  test('partial never becomes trustworthy empty', () {
    for (final b in [
      AnalyticsBatch([], evaluatedAt: now, truncated: true),
      AnalyticsBatch([], evaluatedAt: now, invalidRows: 1),
    ]) {
      expect(
        engine.aggregate(query, b).availability,
        AnalyticsAvailability.partial,
      );
    }
  });
  test(
    'repository RPC, bounds, historical mapping, empty, malformed and errors',
    () async {
      var status = 200;
      Map<String, dynamic> payload = {
        'version': 1,
        'evaluated_at': now.toIso8601String(),
        'truncated': false,
        'observations': [
          {
            'tipo': 'hazard',
            'estado': 'activo',
            'creado_en': now
                .subtract(const Duration(hours: 12))
                .toIso8601String(),
            'expira_en': now
                .subtract(const Duration(hours: 6))
                .toIso8601String(),
          },
          {'tipo': 'invalid'},
        ],
      };
      final client = SupabaseClient(
        'https://example.test',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          expect(
            request.url.path,
            '/rest/v1/rpc/mobility_analytics_observations',
          );
          expect(request.method, 'POST');
          expect(jsonDecode(request.body), {
            'period_start': query.start.toIso8601String(),
            'period_end': query.end.toIso8601String(),
          });
          return http.Response(
            jsonEncode(status == 200 ? payload : {
              'code': '42501',
              'message': 'permission denied for function mobility_analytics_observations',
              'details': null,
              'hint': null,
            }),
            status,
            headers: {'content-type': 'application/json'},
            request: request,
            reasonPhrase: status == 200 ? 'OK' : 'Forbidden',
          );
        }),
      );
      addTearDown(client.dispose);
      final repo = SupabaseMobilityAnalyticsRepository(client: client);
      final result = await repo.fetch(query);
      expect(result.observations.single.category, 'hazard');
      expect(result.observations.single.activeAt(now), isFalse);
      expect(result.invalidRows, 1);
      payload = {...payload, 'observations': []};
      expect((await repo.fetch(query)).observations, isEmpty);
      payload = {...payload, 'truncated': true};
      expect((await repo.fetch(query)).truncated, isTrue);
      payload = {...payload, 'version': 2};
      await expectLater(repo.fetch(query), throwsFormatException);
      status = 403;
      await expectLater(repo.fetch(query), throwsA(isA<PostgrestException>()
        .having((e) => e.code, 'code', '42501')
        .having((e) => e.message, 'message', contains('permission denied'))));
    },
  );
  test('controller transitions, periods and retry', () async {
    final repo = FakeRepository();
    final c = MobilityAnalyticsController(repo, now: () => now);
    addTearDown(c.dispose);
    expect(c.state, AnalyticsLoadState.idle);
    final states = <AnalyticsLoadState>[];
    c.addListener(() => states.add(c.state));
    await c.load();
    expect(c.state, AnalyticsLoadState.empty);
    repo.value = batch([observation()]);
    await c.load(MobilityAnalyticsPeriod.week);
    expect(c.state, AnalyticsLoadState.data);
    await c.load(MobilityAnalyticsPeriod.month);
    expect(repo.queries.map((q) => q.end.difference(q.start).inHours), [
      24,
      168,
      720,
    ]);
    repo.fail = true;
    await c.load();
    expect(c.state, AnalyticsLoadState.error);
    expect(c.snapshot, isNull);
    expect(c.availability, AnalyticsAvailability.unavailable);
    repo.fail = false;
    await c.load();
    expect(c.state, AnalyticsLoadState.data);
    expect(states, contains(AnalyticsLoadState.loading));
  });
  test('stale response and disposal do not overwrite latest query', () async {
    final repo = FakeRepository()..pending = Completer<AnalyticsBatch>();
    final c = MobilityAnalyticsController(repo, now: () => now);
    final old = c.load();
    final pending = repo.pending!;
    repo.pending = null;
    repo.value = batch([observation()]);
    await c.load(MobilityAnalyticsPeriod.month);
    pending.complete(batch());
    await old;
    expect(c.state, AnalyticsLoadState.data);
    expect(c.period, MobilityAnalyticsPeriod.month);
    repo.pending = Completer<AnalyticsBatch>();
    final disposed = c.load();
    c.dispose();
    repo.pending!.complete(batch());
    await disposed;
  });
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('data and full scroll responsive $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeRepository()
        ..value = batch([observation(), observation()]);
      await tester.pumpWidget(
        MaterialApp(
          theme: MobilityTheme.light,
          home: MobilityAnalyticsScreen(repository: repo, now: () => now),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Analítica de movilidad'), findsOneWidget);
      expect(find.text('24 h'), findsOneWidget);
      for (final label in ['7 días', '30 días']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 20; i++) {
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -500),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Distribución por categoría'), findsOneWidget);
      expect(find.text('Actividad temporal'), findsOneWidget);
      expect(find.text('Cobertura de datos'), findsOneWidget);
      expect(find.textContaining('no el flujo total'), findsOneWidget);
      expect(find.textContaining('Fuente:'), findsOneWidget);
    });
  }
  testWidgets('loading, empty, error and retry', (tester) async {
    final repo = FakeRepository()..pending = Completer<AnalyticsBatch>();
    await tester.pumpWidget(
      MaterialApp(
        theme: MobilityTheme.light,
        home: MobilityAnalyticsScreen(repository: repo, now: () => now),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.pending!.complete(batch());
    repo.pending = null;
    await tester.pumpAndSettle();
    expect(
      find.text('No hay reportes registrados para este periodo.'),
      findsOneWidget,
    );
    repo.fail = true;
    await tester.tap(find.text('7 días'));
    await tester.pumpAndSettle();
    expect(find.text('No fue posible cargar la analítica.'), findsOneWidget);
    expect(find.text('Reportes del periodo'), findsNothing);
    repo.fail = false;
    repo.value = batch([observation()]);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Reportes del periodo'), findsOneWidget);
  });
  for (final count in [0, 1, 2]) {
    testWidgets('accessible progress with $count observations', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
      final repo = FakeRepository()..value = count == 0
        ? AnalyticsBatch([], evaluatedAt: now, invalidRows: 1)
        : batch(List.generate(count, (_) => observation()));
      await tester.pumpWidget(MaterialApp(theme: MobilityTheme.light,
        home: MobilityAnalyticsScreen(repository: repo, now: () => now)));
      await tester.pumpAndSettle();
      final bars = tester.widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bars, isNotEmpty);
      for (final bar in bars) {
        expect(bar.value, isNotNull);
        expect(bar.value!.isFinite, isTrue);
        expect(bar.value, inInclusiveRange(0.0, 1.0));
        final percent = double.parse(bar.semanticsValue!.replaceAll('%', ''));
        expect(percent, closeTo(100 * bar.value!, 0.05));
        expect(percent, inInclusiveRange(0.0, 100.0));
      }
      final first = bars.first;
      expect(first.value, count == 0 ? 0.0 : 1.0);
      expect(first.semanticsLabel, 'Accidente · $count ${count == 1 ? 'reporte' : 'reportes'}');
      expect(first.semanticsValue, count == 0 ? '0.0%' : '100.0%');
      expect(tester.takeException(), isNull);
      if (count == 0) {
        expect(find.text('Datos parciales'), findsOneWidget);
        expect(find.text('No hay reportes registrados para este periodo.'), findsNothing);
      }
      } finally {
        semantics.dispose();
      }
    });
  }
  testWidgets('drawer preserves entries and opens analytics callback', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppNavigationDrawer(
            onHome: () {},
            onRoutes: () {},
            onNearby: () {},
            onProfile: () {},
            onSignOut: () {},
            onRoadIncidents: () {},
            onAnalytics: () => opened = true,
          ),
        ),
      ),
    );
    expect(find.text('Reportes de la vía'), findsOneWidget);
    await tester.tap(find.text('Analítica de movilidad'));
    expect(opened, isTrue);
    expect(find.text('Perfil'), findsOneWidget);
  });
  testWidgets(
    'partial with no valid observations is not a successful empty state',
    (tester) async {
      final repo = FakeRepository()
        ..value = AnalyticsBatch([], evaluatedAt: now, invalidRows: 1);
      await tester.pumpWidget(
        MaterialApp(
          theme: MobilityTheme.light,
          home: MobilityAnalyticsScreen(repository: repo, now: () => now),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Datos parciales'), findsOneWidget);
      expect(
        find.text('No hay reportes registrados para este periodo.'),
        findsNothing,
      );
      expect(find.text('Registros excluidos por calidad: 1'), findsOneWidget);
    },
  );
}
