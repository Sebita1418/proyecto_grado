import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/mobility/analytics/mobility_analytics.dart';
import 'package:transporte_inteligente/mobility/analytics/mobility_analytics_repository.dart';
import 'package:transporte_inteligente/mobility/analytics/historical_departure_guidance.dart';
import 'package:transporte_inteligente/controllers/historical_departure_guidance_controller.dart';

final end = DateTime.utc(2026, 10, 7, 5); // Bogota midnight Wednesday.
final query = MobilityAnalyticsQuery(
  end.subtract(const Duration(days: 28)),
  end,
);
final selected = DateTime.utc(2026, 10, 14, 13); // Wednesday 08:00 Bogota.
AnalyticsObservation row(DateTime created) => AnalyticsObservation(
  category: 'hazard',
  createdAt: created,
  expiresAt: created.add(const Duration(hours: 6)),
  status: 'activo',
);

/// Fixtures only: four observations/hour repeated across four full weeks.
AnalyticsBatch denseBatch({
  bool uniform = false,
  bool truncated = false,
  int invalid = 0,
}) {
  final rows = <AnalyticsObservation>[];
  for (
    var date = query.start;
    date.isBefore(query.end);
    date = date.add(const Duration(days: 1))
  ) {
    for (var hour = 0; hour < 24; hour++) {
      rows.add(row(date.add(Duration(hours: hour, minutes: 10))));
      if (!uniform && hour != 8) {
        rows.add(row(date.add(Duration(hours: hour, minutes: 20))));
      }
    }
  }
  return AnalyticsBatch(
    rows,
    evaluatedAt: end,
    truncated: truncated,
    invalidRows: invalid,
  );
}

HistoricalDepartureGuidance evaluate(
  AnalyticsBatch batch, {
  MobilityAnalyticsQuery? period,
  DateTime? departure,
}) => const HistoricalDepartureGuidanceEvaluator().evaluate(
  query: period ?? query,
  batch: batch,
  selectedDeparture: departure ?? selected,
);

class FakeHistoricalRepository implements MobilityAnalyticsRepository {
  AnalyticsBatch value = denseBatch();
  bool fail = false;
  final queries = <MobilityAnalyticsQuery>[];
  final pending = <Completer<AnalyticsBatch>>[];
  bool delayed = false;
  @override
  Future<AnalyticsBatch> fetch(MobilityAnalyticsQuery query) async {
    queries.add(query);
    if (fail) throw StateError('offline');
    if (delayed) {
      final completer = Completer<AnalyticsBatch>();
      pending.add(completer);
      return completer.future;
    }
    return value;
  }
}

void main() {
  test(
    'America/Bogota midnight/day/hour transition independent of local timezone',
    () {
      expect(
        BogotaCalendar.fields(DateTime.utc(2026, 10, 7, 4, 59)).weekday,
        DateTime.tuesday,
      );
      expect(BogotaCalendar.fields(DateTime.utc(2026, 10, 7, 4, 59)).hour, 23);
      expect(
        BogotaCalendar.fields(DateTime.utc(2026, 10, 7, 5)).weekday,
        DateTime.wednesday,
      );
      expect(BogotaCalendar.fields(DateTime.utc(2026, 10, 7, 5)).hour, 0);
      final s = evaluate(
        AnalyticsBatch([
          row(DateTime.utc(2026, 10, 6, 4, 59)),
          row(DateTime.utc(2026, 10, 6, 5)),
        ], evaluatedAt: end),
      );
      expect(
        s.metrics
            .firstWhere((m) => m.weekday == DateTime.monday && m.hour == 23)
            .observations,
        1,
      );
      expect(
        s.metrics
            .firstWhere((m) => m.weekday == DateTime.tuesday && m.hour == 0)
            .observations,
        1,
      );
    },
  );
  test('sufficient complete repeated sample identifies observed hour, not future traffic', () {
    final s = evaluate(denseBatch());
    expect(s.status, HistoricalGuidanceStatus.observed);
    expect(s.completeDays, 28);
    expect(s.weekdayOccurrences, 4);
    expect(s.lowerActivity.single.hour, 8);
    expect(s.lowerActivity.single.observations, 4);
    expect(s.lowerActivity.single.datesWithReports, 4);
    expect(s.selectedMetric.hour, 8);
    expect(s.metrics.length, 168);
    expect(() => s.metrics.clear(), throwsUnsupportedError);
    expect(() => s.lowerActivity.clear(), throwsUnsupportedError);
    expect(
      s.metrics.map((m) => m.observations).reduce((a, b) => a + b),
      s.completeDayObservations,
    );
  });
  test('thresholds: short coverage, sparse global sample and missing hourly/day repetitions reject orientation', () {
    final dense = denseBatch();
    expect(
      evaluate(
        dense,
        period: MobilityAnalyticsQuery(
          query.start.add(const Duration(days: 1)),
          query.end,
        ),
      ).status,
      HistoricalGuidanceStatus.partial,
    ); // Out-of-query fixture rows are invalid coverage.
    final shortQuery = MobilityAnalyticsQuery(
      query.start.add(const Duration(days: 1)),
      query.end,
    );
    final shortBatch = AnalyticsBatch(
      dense.observations.where((o) => shortQuery.contains(o.createdAt)),
      evaluatedAt: end,
    );
    expect(
      evaluate(shortBatch, period: shortQuery).status,
      HistoricalGuidanceStatus.insufficient,
    );
    expect(
      evaluate(AnalyticsBatch(dense.observations.take(99), evaluatedAt: end))
          .status,
      HistoricalGuidanceStatus.insufficient,
    );
    final zeroHour = dense.observations.where(
      (o) =>
          !(BogotaCalendar.fields(o.createdAt).weekday == DateTime.wednesday &&
              BogotaCalendar.fields(o.createdAt).hour == 8),
    );
    expect(
      evaluate(AnalyticsBatch(zeroHour, evaluatedAt: end)).status,
      HistoricalGuidanceStatus.insufficient,
    );
    final oneDate = dense.observations.where(
      (o) =>
          !(BogotaCalendar.fields(o.createdAt).weekday == DateTime.wednesday &&
              BogotaCalendar.fields(o.createdAt).hour == 8 &&
              BogotaCalendar.date(o.createdAt) != '2026-09-09'),
    );
    expect(
      evaluate(AnalyticsBatch(oneDate, evaluatedAt: end)).status,
      HistoricalGuidanceStatus.insufficient,
    );
    final missingDay = dense.observations.where(
      (o) => BogotaCalendar.date(o.createdAt) != '2026-09-09',
    );
    expect(
      evaluate(AnalyticsBatch(missingDay, evaluatedAt: end)).status,
      HistoricalGuidanceStatus.insufficient,
    );
  });
  test('empty is successful absence, partial/future/truncated/invalid never produce guidance', () {
    final empty = evaluate(AnalyticsBatch([], evaluatedAt: end));
    expect(empty.status, HistoricalGuidanceStatus.empty);
    expect(empty.totalObservations, 0);
    expect(empty.lowerActivity, isEmpty);
    for (final b in [
      denseBatch(truncated: true),
      denseBatch(invalid: 1),
      AnalyticsBatch([], evaluatedAt: end, truncated: true),
      AnalyticsBatch(
        denseBatch().observations,
        evaluatedAt: end.subtract(const Duration(minutes: 1)),
      ),
    ]) {
      expect(evaluate(b).status, HistoricalGuidanceStatus.partial);
      expect(evaluate(b).lowerActivity, isEmpty);
    }
  });
  test('partial boundary days excluded; half-open query; no extrapolation, ties and order determinism', () {
    final period = MobilityAnalyticsQuery(
      query.start.subtract(const Duration(hours: 1)),
      query.end.add(const Duration(hours: 1)),
    );
    final b = AnalyticsBatch([
      ...denseBatch().observations,
      row(period.start),
      row(query.end.add(const Duration(minutes: 10))),
    ], evaluatedAt: period.end);
    final s = evaluate(b, period: period);
    expect(s.completeDays, 28);
    expect(s.totalObservations - s.completeDayObservations, 2);
    final reverse = evaluate(
      AnalyticsBatch(b.observations.reversed, evaluatedAt: period.end),
      period: period,
    );
    expect(
      reverse.metrics.map(
        (m) => (
          m.weekday,
          m.hour,
          m.observations,
          m.occurrences,
          m.datesWithReports,
        ),
      ),
      s.metrics.map(
        (m) => (
          m.weekday,
          m.hour,
          m.observations,
          m.occurrences,
          m.datesWithReports,
        ),
      ),
    );
    expect(
      evaluate(denseBatch(uniform: true)).status,
      HistoricalGuidanceStatus.insufficient,
    );
    final outside = evaluate(
      AnalyticsBatch([row(query.end)], evaluatedAt: end),
    );
    expect(outside.excludedRows, 1);
    expect(outside.status, HistoricalGuidanceStatus.partial);
  });
  test(
    'presentation result is aggregate, not a projection of personal data',
    () {
      final observation = AnalyticsObservation.fromMap({
        'tipo': 'hazard',
        'creado_en': query.start.toIso8601String(),
        'expira_en': query.start
            .add(const Duration(hours: 6))
            .toIso8601String(),
        'estado': 'activo',
        'usuario_id': 'private-id',
        'latitud': 7.1,
        'longitud': -73.1,
        'descripcion': 'private text',
      });
      final s = evaluate(AnalyticsBatch([observation], evaluatedAt: end));
      expect(s.totalObservations, 1);
      expect(s.metrics.every((m) => m.observations >= 0), isTrue);
      expect(s.reason, isNot(contains('private')));
    },
  );
  test('controller loads same analytics repository once, preserves latest selection and caches for 10 minutes', () async {
    final repo = FakeHistoricalRepository()..delayed = true;
    var now = end;
    final c = HistoricalDepartureGuidanceController(repo, now: () => now);
    addTearDown(c.dispose);
    expect(c.state, HistoricalGuidanceLoadState.idle);
    final first = c.load(selected);
    expect(c.state, HistoricalGuidanceLoadState.loading);
    final other = selected.add(const Duration(days: 1));
    await c.load(other);
    expect(repo.queries.length, 1);
    repo.pending.single.complete(denseBatch());
    await first;
    expect(c.result!.selectedDeparture, other);
    expect(c.state, HistoricalGuidanceLoadState.data);
    await c.load(selected);
    expect(repo.queries.length, 1);
    expect(
      repo.queries.single.end.difference(repo.queries.single.start),
      const Duration(days: 30),
    );
    now = end.add(const Duration(minutes: 10));
    final next = c.load(selected);
    expect(repo.queries.length, 2);
    repo.pending.last.complete(AnalyticsBatch([], evaluatedAt: now));
    await next;
    expect(c.result!.status, HistoricalGuidanceStatus.empty);
  });
  test('error is not zero; retry, stale force response and disposal', () async {
    final repo = FakeHistoricalRepository()..fail = true;
    final c = HistoricalDepartureGuidanceController(repo, now: () => end);
    await c.load(selected);
    expect(c.state, HistoricalGuidanceLoadState.error);
    expect(c.result, isNull);
    repo.fail = false;
    await c.retry();
    expect(c.state, HistoricalGuidanceLoadState.data);
    repo.delayed = true;
    final older = c.retry();
    final newest = c.load(selected.add(const Duration(days: 1)), force: true);
    repo.pending.last.complete(AnalyticsBatch([], evaluatedAt: end));
    await newest;
    repo.pending.first.complete(denseBatch());
    await older;
    expect(c.result!.status, HistoricalGuidanceStatus.empty);
    expect(c.result!.selectedDeparture, selected.add(const Duration(days: 1)));
    final pending = c.retry();
    c.dispose();
    repo.pending.last.complete(denseBatch());
    await pending;
  });
}
