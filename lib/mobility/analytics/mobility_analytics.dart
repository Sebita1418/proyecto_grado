enum MobilityAnalyticsPeriod {
  day(Duration(hours: 24), '24 h'),
  week(Duration(days: 7), '7 días'),
  month(Duration(days: 30), '30 días');

  const MobilityAnalyticsPeriod(this.duration, this.label);
  final Duration duration;
  final String label;
}

enum AnalyticsAvailability { available, empty, partial, unavailable }

/// UTC, half-open interval [start, end). At most 30 days.
class MobilityAnalyticsQuery {
  MobilityAnalyticsQuery(DateTime start, DateTime end)
    : start = start.toUtc(),
      end = end.toUtc() {
    if (!this.start.isBefore(this.end) ||
        this.end.difference(this.start) > const Duration(days: 30)) {
      throw ArgumentError('El periodo debe ser mayor a cero y hasta 30 días');
    }
  }
  factory MobilityAnalyticsQuery.forPeriod(
    MobilityAnalyticsPeriod period,
    DateTime now,
  ) => MobilityAnalyticsQuery(now.subtract(period.duration), now);
  final DateTime start, end;
  bool contains(DateTime time) => !time.isBefore(start) && time.isBefore(end);
}

/// Database vocabulary, independent of Flutter's operational enum/icons.
const analyticsCategories = <String, String>{
  'accident': 'Accidente',
  'congestion': 'Congestión',
  'road_work': 'Obra en la vía',
  'road_closed': 'Vía cerrada',
  'hazard': 'Peligro / Obstáculo',
  'other': 'Otro',
};

DateTime parseAnalyticsTimestamp(String value) {
  if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
    throw const FormatException('Timestamp sin zona horaria explícita');
  }
  return DateTime.parse(value).toUtc();
}

class AnalyticsObservation {
  AnalyticsObservation({
    required this.category,
    required DateTime createdAt,
    required DateTime expiresAt,
    required this.status,
  }) : createdAt = createdAt.toUtc(),
       expiresAt = expiresAt.toUtc() {
    if (!analyticsCategories.containsKey(category) ||
        !this.expiresAt.isAfter(this.createdAt) ||
        !const ['activo', 'cancelado'].contains(status)) {
      throw const FormatException('Observación inválida');
    }
  }
  factory AnalyticsObservation.fromMap(Map<String, dynamic> row) =>
      AnalyticsObservation(
        category: row['tipo'] as String,
        createdAt: parseAnalyticsTimestamp(row['creado_en'] as String),
        expiresAt: parseAnalyticsTimestamp(row['expira_en'] as String),
        status: row['estado'] as String,
      );
  final String category, status;
  final DateTime createdAt, expiresAt;
  bool activeAt(DateTime now) => status == 'activo' && expiresAt.isAfter(now);
}

class AnalyticsBatch {
  AnalyticsBatch(
    Iterable<AnalyticsObservation> observations, {
    required DateTime evaluatedAt,
    this.truncated = false,
    this.invalidRows = 0,
  }) : observations = List.unmodifiable(observations),
       evaluatedAt = evaluatedAt.toUtc();
  final List<AnalyticsObservation> observations;
  final DateTime evaluatedAt;
  final bool truncated;
  final int invalidRows;
}

class TemporalMobilityMetric {
  const TemporalMobilityMetric(this.start, this.end, this.count);
  final DateTime start, end;
  final int count;
}

class MobilityAnalyticsSnapshot {
  MobilityAnalyticsSnapshot({
    required this.query,
    required this.updatedAt,
    required this.availability,
    required this.total,
    required this.active,
    required this.expired,
    required this.cancelled,
    required Map<String, int> categories,
    required Iterable<TemporalMobilityMetric> temporal,
    required this.invalidRows,
    required this.truncated,
  }) : categories = Map.unmodifiable(categories),
       temporal = List.unmodifiable(temporal);
  final MobilityAnalyticsQuery query;
  final DateTime updatedAt;
  final AnalyticsAvailability availability;
  final int total, active, expired, cancelled, invalidRows;
  final bool truncated;
  final Map<String, int> categories;
  final List<TemporalMobilityMetric> temporal;
  String? get predominantCategory {
    if (total < 2) return null;
    final maximum = categories.values.fold(0, (a, b) => a > b ? a : b);
    final winners = categories.keys
        .where((k) => categories[k] == maximum)
        .toList();
    return winners.length == 1 ? winners.single : null;
  }

  List<TemporalMobilityMetric> get peakActivity {
    final maximum = temporal.fold(0, (int a, b) => a > b.count ? a : b.count);
    return List.unmodifiable(
      temporal.where((b) => maximum > 0 && b.count == maximum),
    );
  }
}

/// Pure deterministic aggregation. Expired excludes cancelled for disjoint totals.
class MobilityAnalyticsEngine {
  const MobilityAnalyticsEngine();
  MobilityAnalyticsSnapshot aggregate(
    MobilityAnalyticsQuery query,
    AnalyticsBatch batch,
  ) {
    final observations = batch.observations
        .where((o) => query.contains(o.createdAt))
        .toList();
    final categories = {for (final key in analyticsCategories.keys) key: 0};
    final step = query.end.difference(query.start) <= const Duration(hours: 24)
        ? const Duration(hours: 1)
        : const Duration(days: 1);
    final counts = List<int>.filled(
      (query.end.difference(query.start).inMicroseconds / step.inMicroseconds)
          .ceil(),
      0,
    );
    var active = 0, expired = 0, cancelled = 0;
    for (final o in observations) {
      categories[o.category] = categories[o.category]! + 1;
      counts[o.createdAt.difference(query.start).inMicroseconds ~/
          step.inMicroseconds]++;
      if (o.status == 'cancelado') {
        cancelled++;
      } else if (o.activeAt(batch.evaluatedAt)) {
        active++;
      } else {
        expired++;
      }
    }
    return MobilityAnalyticsSnapshot(
      query: query,
      updatedAt: batch.evaluatedAt,
      availability: batch.truncated || batch.invalidRows > 0
          ? AnalyticsAvailability.partial
          : observations.isEmpty
          ? AnalyticsAvailability.empty
          : AnalyticsAvailability.available,
      total: observations.length,
      active: active,
      expired: expired,
      cancelled: cancelled,
      categories: categories,
      invalidRows: batch.invalidRows,
      truncated: batch.truncated,
      temporal: List.generate(counts.length, (i) {
        final start = query.start.add(step * i);
        final end = start.add(step);
        return TemporalMobilityMetric(
          start,
          end.isAfter(query.end) ? query.end : end,
          counts[i],
        );
      }),
    );
  }
}
