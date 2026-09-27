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
    this.compact = false,
  });

  final MobilityRecommendation recommendation;
  final int suggestedIndex;
  final int selectedIndex;
  final bool manuallySelected;
  final bool usesDefaultModes;
  final bool compact;

  void _showExplanation(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Por qué esta ruta',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              Text('Ruta recomendada: alternativa ${suggestedIndex + 1}.'),
              Text('Ruta seleccionada: alternativa ${selectedIndex + 1}.'),
              const SizedBox(height: 12),
              for (final reason in recommendation.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(reason.explanation),
                ),
              if (usesDefaultModes)
                const Text(
                  'Sin modos guardados: se usa el flujo vehicular por defecto.',
                ),
              const SizedBox(height: 12),
              const Text(
                'Puedes elegir otra alternativa sin volver a calcular.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          leading: const Icon(Icons.auto_awesome_outlined),
          title: Text(
            manuallySelected ? 'Selección manual' : 'Ruta sugerida',
            style: theme.textTheme.titleSmall,
          ),
          subtitle: Text(
            'Recomendada: alternativa ${suggestedIndex + 1}. Seleccionada: ${selectedIndex + 1}.',
          ),
          trailing: const Tooltip(
            message: 'Por qué esta ruta',
            child: Icon(Icons.info_outline),
          ),
          onTap: () => _showExplanation(context),
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
