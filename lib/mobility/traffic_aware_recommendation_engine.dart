import '../services/route_traffic_service.dart';
import 'mobility_context.dart';
import 'mobility_recommendation.dart';
import 'mobility_recommendation_engine.dart';
import 'route_option.dart';
import 'transport_mode.dart';

/// Keeps the validated incident/OSRM decision and exposes traffic quality.
/// A spatially close fragment without direction/full coverage cannot rank routes.
class TrafficAwareRecommendationEngine implements MobilityRecommendationEngine {
  const TrafficAwareRecommendationEngine({
    required this.engine,
    required this.traffic,
  });
  final MobilityRecommendationEngine engine;
  final RouteTrafficService traffic;

  @override
  Future<MobilityRecommendation> recommend(
    MobilityContext context,
    List<RouteOption> options,
  ) async {
    final decision = await engine.recommend(context, options);
    final observations = await traffic.inspect(
      options.map((o) => o.route).toList(),
    );
    final selected = options.indexWhere((o) => o.id == decision.recommended.id);
    return MobilityRecommendation(
      recommended: decision.recommended,
      alternatives: decision.alternatives,
      evaluatedAt: decision.evaluatedAt,
      reasons: [
        ...decision.reasons,
        RecommendationReason(
          factor: RecommendationFactor.preference,
          explanation:
              'Se respetan los modos permitidos para esta consulta: '
              '${context.allowedModes.map((m) => switch (m) {
                TransportMode.driving => 'vehículo',
                TransportMode.walking => 'a pie',
                TransportMode.cycling => 'bicicleta',
                TransportMode.publicTransport => 'transporte público',
              }).join(', ')}. '
              'La comparación de tiempos entre modos usa sus rutas consultadas, sin una puntuación multimodal inventada.',
        ),
        RecommendationReason(
          factor: RecommendationFactor.conditions,
          explanation: selected >= 0 && selected < observations.length
              ? observations[selected].explanation
              : 'Sin observación de tráfico asociada a la alternativa.',
        ),
      ],
    );
  }
}
