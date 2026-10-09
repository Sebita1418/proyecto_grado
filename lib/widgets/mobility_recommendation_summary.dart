import 'package:flutter/material.dart';

import '../mobility/mobility_recommendation.dart';
import '../mobility/route_incident_analysis.dart';
import '../mobility/decision/mobility_data_availability.dart';
import '../mobility/decision/mobility_decision_result.dart';
import '../mobility/transport_mode.dart';
import '../models/route_insight.dart';
import '../theme/mobility_theme.dart';

/// Explains the engine's decision separately from the currently selected route.
class MobilityRecommendationSummary extends StatelessWidget {
  const MobilityRecommendationSummary({
    super.key,
    required this.recommendation,
    required this.suggestedIndex,
    required this.selectedIndex,
    required this.manuallySelected,
    required this.usesDefaultModes,
    this.compact = false,
    this.incidentAnalyses = const [],
    this.updating = false,
    this.decision,
  });

  final MobilityRecommendation recommendation;
  final int suggestedIndex;
  final int selectedIndex;
  final bool manuallySelected;
  final bool usesDefaultModes;
  final bool compact;
  final List<RouteIncidentAnalysis> incidentAnalyses;
  final bool updating;
  final MobilityDecisionResult? decision;

  String _reportEvidence(
    RouteInsight insight,
    MobilityDataStatus status,
  ) => switch (status) {
    MobilityDataStatus.available =>
      insight.reportCount == 0
          ? 'Sin reportes activos pr\u00f3ximos'
          : '${insight.reportCount} reportes activos pr\u00f3ximos en la ruta sugerida',
    MobilityDataStatus.unavailable => 'No disponible en esta consulta',
    MobilityDataStatus.partial => 'Parcial; no permite confirmar ausencia',
    MobilityDataStatus.unknown => 'Desconocido',
  };

  Widget _evidence(BuildContext context, RouteInsight insight) {
    final decision = this.decision;
    if (decision == null) return const SizedBox.shrink();
    final driving = decision.context.options
        .where((option) => option.mode == TransportMode.driving)
        .firstOrNull;
    if (driving == null) return const SizedBox.shrink();
    final data = driving.data;
    final route = decision.recommendation?.recommended;
    final routeSource = route?.source == 'osrm'
        ? 'OSRM'
        : route?.source ?? 'No disponible';
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(MobilityDesign.cardRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informaci\u00f3n considerada',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Rutas y m\u00e9tricas: $routeSource; estimaciones del proveedor.',
          ),
          Text(
            'Reportes viales pr\u00f3ximos: '
            '${_reportEvidence(insight, data.statusOf(MobilityDataKind.roadConditions))}.',
          ),
          const Text('Tr\u00e1fico en tiempo real: no disponible.'),
          const Text('Horario futuro: sin predicci\u00f3n.'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (compact) {
      final insight = RouteInsight(
        recommendation: recommendation,
        analyses: incidentAnalyses,
      );
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MobilityDesign.cardRadius),
              side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.alt_route,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'RUTA SUGERIDA',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      if (manuallySelected) ...[
                        const SizedBox(height: 6),
                        const Chip(
                          avatar: Icon(Icons.touch_app_outlined, size: 16),
                          label: Text('Elegida por ti'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                      const SizedBox(height: 6),
                      if (updating)
                        const Text('Actualizando análisis de movilidad…')
                      else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Alternativa ${suggestedIndex + 1} · ${insight.duration} · ${insight.distance}',
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                insight.duration,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final highlight in insight.highlights.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    highlight,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 4),
                      if (manuallySelected)
                        Text(
                          'Selección manual',
                          style: theme.textTheme.labelMedium,
                        ),
                      Text(
                        'Seleccionada: alternativa ${selectedIndex + 1}',
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                ExpansionTile(
                  title: const Text('¿Por qué esta ruta?'),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  children: [
                    Text(
                      'Análisis de movilidad',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (updating)
                      const Text('Actualizando condiciones reportadas…')
                    else ...[
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Text('Duración: ${insight.duration}'),
                          Text('Distancia: ${insight.distance}'),
                          Text(
                            'Reportes próximos: ${insight.reportCount ?? 'No disponibles'}',
                          ),
                          Text(
                            'Cierres próximos: ${insight.closureCount ?? 'No disponibles'}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(insight.comparison),
                      _evidence(context, insight),
                      for (final explanation in insight.explanations)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            explanation,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      if (usesDefaultModes)
                        const Text(
                          'Sin modos guardados: se usa el flujo vehicular por defecto.',
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        'Puedes elegir otra alternativa sin volver a calcular.',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              manuallySelected ? 'Selección manual' : 'Ruta sugerida',
              style: theme.textTheme.titleSmall,
            ),
            Text(
              manuallySelected
                  ? selectedIndex == suggestedIndex
                        ? 'Elegiste la alternativa ${selectedIndex + 1}; coincide con la sugerencia del cálculo.'
                        : 'Elegiste la alternativa ${selectedIndex + 1}. La sugerencia del cálculo fue la alternativa ${suggestedIndex + 1}.'
                  : 'Recomendada: alternativa ${suggestedIndex + 1}. Seleccionada: ${selectedIndex + 1}.',
            ),
            Text(
              '${manuallySelected ? 'Motivo de la sugerencia: ' : ''}'
              '${recommendation.reasons.map((reason) => reason.explanation).join(' ')}',
              style: theme.textTheme.bodySmall,
            ),
            if (usesDefaultModes)
              Text(
                'Sin modos guardados: se usa el flujo vehicular por defecto.',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
