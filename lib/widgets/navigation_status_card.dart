import 'package:flutter/material.dart';

import '../navigation/navigation_session.dart';
import '../navigation/navigation_instruction_presentation.dart';
import '../theme/mobility_theme.dart';

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
    final failed = session.state == NavigationState.rerouteFailed;
    final alert = failed || session.state == NavigationState.offRoutePending;
    final background = session.arrived
        ? const Color(0xFFE6F4EC)
        : failed
        ? colors.errorContainer
        : alert
        ? const Color(0xFFFFF2D9)
        : colors.primaryContainer;
    final foreground = session.arrived
        ? MobilityDesign.positive
        : failed
        ? colors.onErrorContainer
        : alert
        ? MobilityDesign.warning
        : colors.onPrimaryContainer;
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Próxima maniobra',
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(MobilityDesign.cardRadius),
        color: background,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                session.arrived
                    ? Icons.flag_outlined
                    : instruction?.instructionIcon ?? Icons.route,
                size: 36,
                color: foreground,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: foreground,
                      ),
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

class NavigationStatusCard extends StatefulWidget {
  const NavigationStatusCard({super.key, required this.session});
  final NavigationSession session;

  @override
  State<NavigationStatusCard> createState() => _NavigationStatusCardState();
}

class _NavigationStatusCardState extends State<NavigationStatusCard> {
  bool _expanded = true;
  NavigationSession get session => widget.session;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 6,
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MobilityDesign.sheetRadius),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: .7),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.navigation_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Navegación activa',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: _expanded
                    ? 'Minimizar navegación'
                    : 'Expandir navegación',
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_more : Icons.expand_less),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_expanded)
            Text(
              session.arrived
                  ? 'Has llegado a tu destino'
                  : '${(session.remainingDuration / 60).ceil()} min estimados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          if (_expanded)
            Text(
              session.projection == null
                  ? '${(session.remainingDistance / 1000).toStringAsFixed(1)} km de ruta · esperando GPS'
                  : '${(session.remainingDistance / 1000).toStringAsFixed(1)} km restantes · estimación por GPS',
            ),
          Text(
            session.destination,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!session.following)
            TextButton.icon(
              onPressed: session.recenter,
              icon: const Icon(Icons.my_location),
              label: const Text('Volver a seguir mi ubicación'),
            ),
          const SizedBox(height: 8),
          if (_expanded)
            LinearProgressIndicator(
              value: session.progress,
              semanticsLabel: 'Progreso de la ruta',
              semanticsValue: '${(session.progress * 100).round()} %',
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
  );
}
