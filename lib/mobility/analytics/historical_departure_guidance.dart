import 'mobility_analytics.dart';

/// Civil calendar fields for modern America/Bogota (UTC-05, no DST).
/// Returned UTC container represents civil fields, NOT a shifted real instant.
abstract final class BogotaCalendar {
  static const zone = 'America/Bogota';
  static const offset = Duration(hours: -5);
  static DateTime fields(DateTime instant) => instant.toUtc().add(offset);
  static DateTime midnight(DateTime civil) =>
      DateTime.utc(civil.year, civil.month, civil.day);
  static String date(DateTime instant) =>
      fields(instant).toIso8601String().substring(0, 10);
  static String label(DateTime instant) =>
      '${fields(instant).toIso8601String().substring(0, 16).replaceAll('T', ' ')} UTC−05';
}

enum HistoricalGuidanceStatus { observed, insufficient, empty, partial }

class HistoricalHourMetric {
  const HistoricalHourMetric({
    required this.weekday,
    required this.hour,
    required this.observations,
    required this.occurrences,
    required this.datesWithReports,
  });
  final int weekday, hour, observations, occurrences, datesWithReports;
}

class HistoricalDepartureGuidance {
  HistoricalDepartureGuidance({
    required this.query,
    required this.updatedAt,
    required this.selectedDeparture,
    required this.status,
    required this.reason,
    required this.totalObservations,
    required this.completeDayObservations,
    required this.completeDays,
    required this.weekdayOccurrences,
    required this.excludedRows,
    required this.truncated,
    required Iterable<HistoricalHourMetric> metrics,
    required Iterable<HistoricalHourMetric> lowerActivity,
  }) : metrics = List.unmodifiable(metrics),
       lowerActivity = List.unmodifiable(lowerActivity);
  final MobilityAnalyticsQuery query;
  final DateTime updatedAt, selectedDeparture;
  final HistoricalGuidanceStatus status;
  final String reason;
  final int totalObservations,
      completeDayObservations,
      completeDays,
      weekdayOccurrences,
      excludedRows;
  final bool truncated;
  final List<HistoricalHourMetric> metrics, lowerActivity;
  int get selectedWeekday => BogotaCalendar.fields(selectedDeparture).weekday;
  int get selectedHour => BogotaCalendar.fields(selectedDeparture).hour;
  HistoricalHourMetric get selectedMetric => metrics.firstWhere(
    (m) => m.weekday == selectedWeekday && m.hour == selectedHour,
  );
}

/// Descriptive evidence policy, not statistical confidence or a forecast.
class HistoricalDepartureGuidanceEvaluator {
  const HistoricalDepartureGuidanceEvaluator();
  static const minimumCompleteDays = 28;
  static const minimumObservations = 100;
  static const minimumWeekdayOccurrences = 4;
  static const minimumReportsPerDate = 12;
  static const minimumReportsPerHour = 4;
  static const minimumDatesPerHour = 3;

  HistoricalDepartureGuidance evaluate({
    required MobilityAnalyticsQuery query,
    required AnalyticsBatch batch,
    required DateTime selectedDeparture,
  }) {
    final start = BogotaCalendar.fields(query.start);
    final end = BogotaCalendar.fields(query.end);
    final cutoff = BogotaCalendar.fields(batch.evaluatedAt);
    final effectiveEnd = end.isAfter(cutoff) ? cutoff : end;
    final firstMidnight = BogotaCalendar.midnight(start);
    final first = start == firstMidnight
        ? firstMidnight
        : firstMidnight.add(const Duration(days: 1));
    final last = BogotaCalendar.midnight(effectiveEnd);
    final dates = <DateTime>[];
    for (
      var date = first;
      date.isBefore(last);
      date = date.add(const Duration(days: 1))
    ) {
      dates.add(date);
    }
    final dateSet = dates.toSet();
    final counts = <(int, int), int>{};
    final reportingDates = <(int, int), Set<DateTime>>{};
    final dateCounts = {for (final date in dates) date: 0};
    var valid = 0, complete = 0, excluded = batch.invalidRows;
    for (final observation in batch.observations) {
      if (!query.contains(observation.createdAt) ||
          observation.createdAt.isAfter(batch.evaluatedAt)) {
        excluded++;
        continue;
      }
      valid++;
      final local = BogotaCalendar.fields(observation.createdAt);
      final date = BogotaCalendar.midnight(local);
      if (!dateSet.contains(date)) continue;
      complete++;
      dateCounts[date] = dateCounts[date]! + 1;
      final key = (local.weekday, local.hour);
      counts[key] = (counts[key] ?? 0) + 1;
      (reportingDates[key] ??= <DateTime>{}).add(date);
    }
    final occurrences = {
      for (var day = 1; day <= 7; day++)
        day: dates.where((date) => date.weekday == day).length,
    };
    final metrics = [
      for (var day = 1; day <= 7; day++)
        for (var hour = 0; hour < 24; hour++)
          HistoricalHourMetric(
            weekday: day,
            hour: hour,
            observations: counts[(day, hour)] ?? 0,
            occurrences: occurrences[day]!,
            datesWithReports: reportingDates[(day, hour)]?.length ?? 0,
          ),
    ];
    final weekday = BogotaCalendar.fields(selectedDeparture).weekday;
    final relevant = metrics.where((m) => m.weekday == weekday).toList();
    final repeatedDates = dates
        .where((date) => date.weekday == weekday)
        .toList();
    var status = HistoricalGuidanceStatus.insufficient;
    var reason = 'Datos insuficientes para orientar horarios';
    var lower = <HistoricalHourMetric>[];
    if (batch.truncated ||
        excluded > 0 ||
        query.end.isAfter(batch.evaluatedAt)) {
      status = HistoricalGuidanceStatus.partial;
      reason = 'Cobertura parcial: no permite orientar horarios.';
    } else if (valid == 0) {
      status = HistoricalGuidanceStatus.empty;
      reason = 'Sin reportes registrados en el periodo consultado.';
    } else if (query.start.year < 2000 ||
        selectedDeparture.toUtc().year < 2000) {
      reason = 'Calendario fuera del alcance moderno America/Bogota de esta metodología.';
    } else if (dates.length >= minimumCompleteDays &&
        complete >= minimumObservations &&
        repeatedDates.length >= minimumWeekdayOccurrences &&
        repeatedDates.every(
          (date) => dateCounts[date]! >= minimumReportsPerDate,
        ) &&
        relevant.every(
          (m) =>
              m.observations >= minimumReportsPerHour &&
              m.datesWithReports >= minimumDatesPerHour,
        )) {
      final minimum = relevant
          .map((m) => m.observations)
          .reduce((a, b) => a < b ? a : b);
      final maximum = relevant
          .map((m) => m.observations)
          .reduce((a, b) => a > b ? a : b);
      if (minimum < maximum) {
        status = HistoricalGuidanceStatus.observed;
        reason = 'Menor actividad histórica de reportes';
        lower = relevant.where((m) => m.observations == minimum).toList();
      } else {
        reason = 'Datos suficientes para describir, sin diferencia observada entre franjas.';
      }
    }
    return HistoricalDepartureGuidance(
      query: query,
      updatedAt: batch.evaluatedAt,
      selectedDeparture: selectedDeparture.toUtc(),
      status: status,
      reason: reason,
      totalObservations: valid,
      completeDayObservations: complete,
      completeDays: dates.length,
      weekdayOccurrences: repeatedDates.length,
      excludedRows: excluded,
      truncated: batch.truncated,
      metrics: metrics,
      lowerActivity: lower,
    );
  }
}
