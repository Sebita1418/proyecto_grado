import 'package:flutter/foundation.dart';

import '../mobility/analytics/mobility_analytics.dart';
import '../mobility/analytics/mobility_analytics_repository.dart';

enum AnalyticsLoadState { idle, loading, data, empty, error }

class MobilityAnalyticsController extends ChangeNotifier {
  MobilityAnalyticsController(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final MobilityAnalyticsRepository repository;
  final DateTime Function() _now;
  MobilityAnalyticsPeriod period = MobilityAnalyticsPeriod.day;
  AnalyticsLoadState state = AnalyticsLoadState.idle;
  MobilityAnalyticsSnapshot? snapshot;
  AnalyticsAvailability get availability => state == AnalyticsLoadState.error
      ? AnalyticsAvailability.unavailable
      : snapshot?.availability ?? AnalyticsAvailability.unavailable;
  int _revision = 0;
  bool _disposed = false;
  Future<void> load([MobilityAnalyticsPeriod? selected]) async {
    if (_disposed) return;
    period = selected ?? period;
    final revision = ++_revision;
    final query = MobilityAnalyticsQuery.forPeriod(period, _now().toUtc());
    state = AnalyticsLoadState.loading;
    snapshot = null;
    notifyListeners();
    try {
      final batch = await repository.fetch(query);
      if (_disposed || revision != _revision) return;
      snapshot = const MobilityAnalyticsEngine().aggregate(query, batch);
      state = snapshot!.availability == AnalyticsAvailability.empty
          ? AnalyticsLoadState.empty
          : AnalyticsLoadState.data;
    } catch (_) {
      if (_disposed || revision != _revision) return;
      state = AnalyticsLoadState.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    super.dispose();
  }
}
