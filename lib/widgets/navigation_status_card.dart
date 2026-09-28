import 'package:flutter/material.dart';

import '../navigation/navigation_session.dart';

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
    borderRadius: BorderRadius.circular(24),
    color: Theme.of(context).colorScheme.surface,
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
          if (session.notice != null || session.offRoute)
            Semantics(
              liveRegion: true,
              child: Text(session.notice ?? 'Fuera de la ruta'),
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
