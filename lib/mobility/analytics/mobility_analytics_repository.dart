import 'mobility_analytics.dart';

abstract interface class MobilityAnalyticsRepository {
  Future<AnalyticsBatch> fetch(MobilityAnalyticsQuery query);
}
