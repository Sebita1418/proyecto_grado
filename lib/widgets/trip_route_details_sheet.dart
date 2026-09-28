import 'package:flutter/material.dart';

import '../navigation/navigation_session.dart';

class TripRouteDetailsSheet extends StatelessWidget {
  const TripRouteDetailsSheet({super.key, required this.session});
  final NavigationSession session;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final selected = session.selectedRoute!;
          final selection = session.tripContext;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ruta de este viaje',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar ruta del viaje',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Destino: ${session.destination}'),
              Text(
                'Origen: ${selection.originLabel.isEmpty ? '${selected.origin.latitude.toStringAsFixed(5)}, ${selected.origin.longitude.toStringAsFixed(5)}' : selection.originLabel}',
              ),
              const SizedBox(height: 12),
              Text(
                'Ruta elegida: ${(selected.distanceMeters / 1000).toStringAsFixed(1)} km · ${(selected.durationSeconds / 60).ceil()} min estimados por OSRM',
              ),
              if (selection.alternativeIndex != null)
                Text(
                  'Alternativa ${selection.alternativeIndex! + 1} de ${selection.alternativeCount}',
                ),
              Wrap(
                spacing: 8,
                children: [
                  if (selection.fastest)
                    const Chip(
                      avatar: Icon(Icons.schedule, size: 16),
                      label: Text('Más rápida'),
                    ),
                  if (selection.shortest)
                    const Chip(
                      avatar: Icon(Icons.straighten, size: 16),
                      label: Text('Más corta'),
                    ),
                ],
              ),
              if (!identical(selected, session.route)) ...[
                const SizedBox(height: 12),
                Text(
                  'Trazado actualizado durante el viaje: ${(session.route!.distanceMeters / 1000).toStringAsFixed(1)} km desde el punto de recálculo.',
                ),
              ],
              if (selection.recommendation != null &&
                  selection.suggestedIndex != null) ...[
                const Divider(height: 32),
                Text(
                  'Recomendación al planificar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'El motor recomendó la alternativa ${selection.suggestedIndex! + 1}.',
                ),
                for (final reason in selection.recommendation!.reasons)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(reason.explanation),
                  ),
              ],
              const SizedBox(height: 16),
              const Text(
                'La recomendación original no se recalcula con el GPS ni con las novedades de la vía.',
              ),
            ],
          );
        },
      ),
    ),
  );
}
