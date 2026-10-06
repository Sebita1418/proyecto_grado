import 'package:flutter/material.dart';

import '../../mobility/decision/current_mobility_decision_adapter.dart';
import '../../mobility/decision/departure_time_context.dart';
import '../../mobility/decision/mobility_decision_result.dart';
import '../../mobility/decision/mobility_option_availability.dart';
import '../../mobility/transport_mode.dart';
import '../travel_mode_selector.dart';
import 'departure_time_selector.dart';

/// Progressive capability presentation, with no fabricated multimodal metrics.
class MobilityPlannerSection extends StatelessWidget {
  const MobilityPlannerSection({
    super.key,
    required this.departure,
    required this.onDepartureChanged,
    this.result,
    this.busy = false,
  });

  final DepartureTimeContext departure;
  final ValueChanged<DepartureTimeContext> onDepartureChanged;
  final MobilityDecisionResult? result;
  final bool busy;

  Widget _mode(BuildContext context, TransportMode mode) {
    final option =
        result?.context.options.where((o) => o.mode == mode).firstOrNull ??
        const CurrentMobilityDecisionAdapter().option(
          mode,
          departure: departure,
        );
    final excluded =
        result != null &&
        !result!.context.mobilityContext.allowedModes.contains(mode);
    final status = switch (option.status) {
      MobilityOptionStatus.evaluable => 'Disponible para analizar',
      MobilityOptionStatus.insufficientData => 'Informaci\u00f3n insuficiente',
      MobilityOptionStatus.temporarilyUnavailable =>
        'Temporalmente no disponible',
      MobilityOptionStatus.unsupported => 'Todav\u00eda no soportado',
    };
    final detail = mode == TransportMode.driving
        ? excluded
              ? 'No incluido en tus preferencias'
              : busy
              ? 'Actualizando an\u00e1lisis...'
              : status
        : mode == TransportMode.publicTransport
        ? 'Datos de transporte no integrados'
        : 'Informaci\u00f3n de ruta no disponible';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(mode.icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mode.label, style: Theme.of(context).textTheme.titleSmall),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
                if (mode != TransportMode.driving)
                  Text(status, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DepartureTimeSelector(
        value: departure,
        onChanged: onDepartureChanged,
        enabled: !busy,
      ),
      if (departure.isScheduled)
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin informaci\u00f3n temporal suficiente. La hora queda indicada, '
              'pero no podemos recomendar una ruta para condiciones futuras. '
              'Vuelve a Ahora para calcular o iniciar una ruta.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      const SizedBox(height: 10),
      Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mode(context, TransportMode.driving),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Otros medios'),
                subtitle: const Text('3 medios todav\u00eda no soportados'),
                children: [
                  for (final mode in TransportMode.values.skip(1))
                    _mode(context, mode),
                ],
              ),
            ],
          ),
        ),
      ),
      if (result != null &&
          !result!.hasRecommendation &&
          departure.isNow &&
          !busy)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'No hay una recomendaci\u00f3n disponible con estos datos y medios.',
          ),
        ),
      const SizedBox(height: 12),
    ],
  );
}
