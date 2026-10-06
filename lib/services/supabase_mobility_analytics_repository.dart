import 'package:supabase_flutter/supabase_flutter.dart';

import '../mobility/analytics/mobility_analytics.dart';
import '../mobility/analytics/mobility_analytics_repository.dart';

/// Uses a dedicated, authenticated, bounded historical projection.
/// Missing RPC/permissions are errors, never successful empty collections.
class SupabaseMobilityAnalyticsRepository
    implements MobilityAnalyticsRepository {
  SupabaseMobilityAnalyticsRepository({SupabaseClient? client})
    : _providedClient = client;
  final SupabaseClient? _providedClient;
  @override
  Future<AnalyticsBatch> fetch(MobilityAnalyticsQuery query) async {
    final client = _providedClient ?? Supabase.instance.client;
    final result = await client
        .rpc(
          'mobility_analytics_observations',
          params: {
            'period_start': query.start.toIso8601String(),
            'period_end': query.end.toIso8601String(),
          },
        )
        .timeout(const Duration(seconds: 20));
    final payload = Map<String, dynamic>.from(result as Map);
    if (payload['version'] != 1 || payload['truncated'] is! bool) {
      throw const FormatException('Contrato analítico no disponible');
    }
    final observations = <AnalyticsObservation>[];
    var invalid = 0;
    for (final row in payload['observations'] as List) {
      try {
        final observation = AnalyticsObservation.fromMap(
          Map<String, dynamic>.from(row as Map),
        );
        if (!query.contains(observation.createdAt)) {
          invalid++;
        } else {
          observations.add(observation);
        }
      } on FormatException {
        invalid++;
      } on TypeError {
        invalid++;
      }
    }
    return AnalyticsBatch(
      observations,
      evaluatedAt: parseAnalyticsTimestamp(payload['evaluated_at'] as String),
      truncated: payload['truncated'] as bool,
      invalidRows: invalid,
    );
  }
}
