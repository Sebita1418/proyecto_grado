import 'package:flutter/material.dart';

import '../navigation/navigation_session.dart';

class NavigationStatusCard extends StatelessWidget {
  const NavigationStatusCard({super.key, required this.session});
  final NavigationSession session;

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
          Text(
            session.arrived
                ? 'Has llegado a tu destino'
                : '${(session.remainingDuration / 60).ceil()} min estimados',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${(session.remainingDistance / 1000).toStringAsFixed(1)} km restantes · estimación por GPS',
          ),
          Text(
            session.destination,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (session.notice != null || session.offRoute)
            Semantics(
              liveRegion: true,
              child: Text(session.notice ?? 'Fuera de la ruta'),
            ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: session.progress,
            semanticsLabel: 'Progreso de la ruta',
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
