import 'package:flutter/material.dart';

import '../mobility/mobility_recommendation.dart';

/// Explains the engine's decision separately from the currently selected route.
class MobilityRecommendationSummary extends StatelessWidget {
  const MobilityRecommendationSummary({
    super.key,
    required this.recommendation,
    required this.suggestedIndex,
    required this.selectedIndex,
    required this.manuallySelected,
    required this.usesDefaultModes,
  });

  final MobilityRecommendation recommendation;
  final int suggestedIndex;
  final int selectedIndex;
  final bool manuallySelected;
  final bool usesDefaultModes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  : 'Alternativa ${suggestedIndex + 1}, seleccionada inicialmente por el cálculo.',
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
