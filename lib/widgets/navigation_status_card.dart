import 'package:flutter/material.dart';

import '../navigation/navigation_session.dart';
import '../navigation/navigation_instruction_presentation.dart';

class NavigationManeuverCard extends StatelessWidget {
  const NavigationManeuverCard({super.key, required this.session});
  final NavigationSession session;

  @override
  Widget build(BuildContext context) {
    final instruction = session.nextInstruction;
    final distance = session.distanceToInstruction;
    final text = session.arrived
        ? 'Has llegado'
        : session.offRoute || session.notice != null
        ? session.notice ?? 'Fuera de la ruta'
        : instruction?.instructionText ?? 'Sigue la ruta en el mapa';
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Próxima maniobra',
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        color: colors.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                session.arrived
                    ? Icons.flag_outlined
                    : instruction?.instructionIcon ?? Icons.route,
                size: 36,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (!session.arrived &&
                        !session.offRoute &&
                        distance != null)
                      Text(
                        distance >= 1000
                            ? '${(distance / 1000).toStringAsFixed(1)} km'
                            : '${distance.round()} m',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationStatusCard extends StatelessWidget {
  const NavigationStatusCard({
    super.key,
    required this.session,
    this.onShowRoute,
    this.onShowReports,
  });
  final NavigationSession session;
  final VoidCallback? onShowRoute, onShowReports;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final colors = Theme.of(context).colorScheme;
      final expanded = session.panelExpanded;
      final measured = session.projection != null;
      final percent = (session.progress * 100).round();
      return Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(24),
        color: colors.surface,
        child: AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.navigation_outlined,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Viaje activo',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: expanded
                          ? 'Minimizar navegación'
                          : 'Expandir navegación',
                      onPressed: session.togglePanel,
                      icon: Icon(
                        expanded ? Icons.expand_more : Icons.expand_less,
                      ),
                    ),
                  ],
                ),
                Text(
                  session.destination,
                  maxLines: expanded ? null : 1,
                  overflow: expanded ? null : TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (session.arrived) const Text('Has llegado a tu destino'),
                Text(
                  measured
                      ? '$percent % del trazado actual'
                      : 'Esperando ubicación para medir progreso',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: session.progress,
                  semanticsLabel: 'Progreso aproximado de la ruta',
                  semanticsValue: measured
                      ? '$percent %'
                      : 'Sin posición sobre la ruta',
                ),
                if (expanded) ...[
                  const SizedBox(height: 12),
                  Text(
                    measured
                        ? '${(session.remainingDistance / 1000).toStringAsFixed(1)} km restantes · aproximación geométrica'
                        : '${(session.geometryDistance / 1000).toStringAsFixed(1)} km de trazado · esperando GPS',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.gpsState == TripGpsState.available
                        ? session.offRoute
                              ? 'Fuera de la ruta · último progreso conocido'
                              : 'Ubicación GPS disponible'
                        : session.notice ?? 'Esperando ubicación GPS',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (session.canRetryGps)
                    TextButton.icon(
                      onPressed: session.retryGps,
                      icon: const Icon(Icons.gps_fixed),
                      label: const Text('Reintentar GPS'),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (onShowRoute != null)
                        TextButton.icon(
                          onPressed: onShowRoute,
                          icon: const Icon(Icons.route),
                          label: const Text('Ver ruta del viaje'),
                        ),
                      if (onShowReports != null)
                        TextButton.icon(
                          onPressed: onShowReports,
                          icon: const Icon(Icons.report_outlined),
                          label: const Text('Novedades del viaje'),
                        ),
                    ],
                  ),
                ],
                if (!session.following)
                  TextButton.icon(
                    onPressed: session.recenter,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Volver a seguir mi ubicación'),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: session.finish,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Finalizar ruta'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
