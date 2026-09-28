import 'package:flutter/material.dart';

import '../navigation/trip_summary.dart';

class TripSummarySheet extends StatelessWidget {
  const TripSummarySheet({
    super.key,
    required this.summary,
    required this.onPlanAnother,
  });
  final TripSummary summary;
  final VoidCallback onPlanAnother;

  String _time(BuildContext context, DateTime time) {
    final local = time.toLocal();
    final l = MaterialLocalizations.of(context);
    return '${l.formatCompactDate(local)} · ${l.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final minutes = summary.elapsed.inMinutes;
    final elapsed = minutes < 1
        ? '${summary.elapsed.inSeconds} s'
        : '${minutes ~/ 60 > 0 ? '${minutes ~/ 60} h ' : ''}${minutes % 60} min';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.flag_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Resumen del viaje',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar resumen',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              summary.destination,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              summary.reachedDestination
                  ? 'Finalizado cerca del destino'
                  : 'Viaje finalizado por ti',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    elapsed,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: colors.primary),
                  ),
                  const Text('Tiempo transcurrido de la sesión'),
                  const SizedBox(height: 12),
                  Text(
                    '${(summary.selectedRoute.distanceMeters / 1000).toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text('Distancia de la ruta elegida · OSRM'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Origen: ${summary.context.originLabel.isEmpty ? '${summary.selectedRoute.origin.latitude.toStringAsFixed(5)}, ${summary.selectedRoute.origin.longitude.toStringAsFixed(5)}' : summary.context.originLabel}',
            ),
            if (summary.context.alternativeIndex != null)
              Text(
                'Alternativa elegida: ${summary.context.alternativeIndex! + 1}${summary.context.alternativeCount == null ? '' : ' de ${summary.context.alternativeCount}'}',
              ),
            const SizedBox(height: 12),
            Text('Inicio: ${_time(context, summary.startedAt)}'),
            Text('Fin: ${_time(context, summary.finishedAt)}'),
            const SizedBox(height: 12),
            const Text(
              'La distancia de ruta no es una medición de la distancia recorrida. Resumen disponible solo en esta sesión.',
            ),
            if (!summary.hadPosition)
              const Text(
                'No se recibió una ubicación válida durante el viaje.',
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Volver al mapa'),
            ),
            TextButton.icon(
              onPressed: onPlanAnother,
              icon: const Icon(Icons.add_road),
              label: const Text('Planificar otra ruta'),
            ),
          ],
        ),
      ),
    );
  }
}
