import 'package:flutter/material.dart';

import '../models/route_result.dart';

class RouteResultCard extends StatelessWidget {
  const RouteResultCard({
    super.key,
    required this.route,
    required this.originLabel,
    required this.destinationLabel,
    required this.onModify,
  });

  final RouteResult route;
  final String originLabel;
  final String destinationLabel;
  final VoidCallback onModify;

  String get distance =>
      '${(route.distanceMeters / 1000).toStringAsFixed(1)} km';

  String get duration {
    final minutes = (route.durationSeconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining == 0 ? '$hours h' : '$hours h $remaining min';
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalles de la ruta',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.trip_origin),
                  title: const Text('Origen'),
                  subtitle: Text(originLabel),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Destino'),
                  subtitle: Text(destinationLabel),
                ),
                ListTile(
                  leading: const Icon(Icons.straighten),
                  title: const Text('Distancia'),
                  subtitle: Text(distance),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Duración estimada'),
                  subtitle: Text(duration),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: const Icon(Icons.directions_car_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ruta calculada',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                duration,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(distance, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.trip_origin, size: 18, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  originLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Icon(
              Icons.arrow_downward,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ),
          Row(
            children: [
              Icon(Icons.location_on, size: 19, color: colors.tertiary),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  destinationLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onModify,
                  child: const Text('Modificar ruta'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _showDetails(context),
                child: const Text('Ver detalles'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
