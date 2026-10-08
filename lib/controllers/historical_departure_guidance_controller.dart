import 'package:flutter/foundation.dart';

import '../mobility/analytics/mobility_analytics.dart';
import '../mobility/analytics/mobility_analytics_repository.dart';
import '../mobility/analytics/historical_departure_guidance.dart';

enum HistoricalGuidanceLoadState { idle, loading, data, error }

class HistoricalDepartureGuidanceController extends ChangeNotifier {
  HistoricalDepartureGuidanceController(
    this.repository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final MobilityAnalyticsRepository repository;
  final DateTime Function() _now;
  HistoricalGuidanceLoadState state = HistoricalGuidanceLoadState.idle;
  HistoricalDepartureGuidance? result;
  AnalyticsBatch? _batch;
  MobilityAnalyticsQuery? _query;
  DateTime? _cachedAt;
  DateTime? _selected;
  int _revision = 0;
  bool _disposed = false;
  Future<void> load(DateTime departure, {bool force = false}) async {
    if (_disposed) return;
    _selected = departure.toUtc();
    final now = _now().toUtc();
    if (!force &&
        _batch != null &&
        _cachedAt != null &&
        !now.isBefore(_cachedAt!) &&
        now.difference(_cachedAt!) < const Duration(minutes: 10)) {
      _evaluate();
      notifyListeners();
      return;
    }
    // One pending query can serve another selected weekday; use latest selection.
    if (!force && state == HistoricalGuidanceLoadState.loading) return;
    _batch = null;
    _cachedAt = null;
    final revision = ++_revision;
    final query = MobilityAnalyticsQuery.forPeriod(
      MobilityAnalyticsPeriod.month,
      now,
    );
    state = HistoricalGuidanceLoadState.loading;
    result = null;
    notifyListeners();
    try {
      final batch = await repository.fetch(query);
      if (_disposed || revision != _revision) return;
      _query = query;
      _batch = batch;
      _cachedAt = _now().toUtc();
      _evaluate();
    } catch (_) {
      if (_disposed || revision != _revision) return;
      state = HistoricalGuidanceLoadState.error;
      result = null;
      _batch = null;
      _cachedAt = null;
    }
    notifyListeners();
  }

  Future<void> retry() =>
      _selected == null ? Future.value() : load(_selected!, force: true);
  void _evaluate() {
    result = const HistoricalDepartureGuidanceEvaluator().evaluate(
      query: _query!,
      batch: _batch!,
      selectedDeparture: _selected!,
    );
    state = HistoricalGuidanceLoadState.data;
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    super.dispose();
  }
}
