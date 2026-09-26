import 'package:flutter/material.dart';

import '../models/route_result.dart';

/// Modern card presenting calculated route metrics and navigation endpoints.
///
/// Follows visual priority: duration -> distance -> destination -> actions.
/// Preserves exact testable strings and details sheet.
class RouteResultCard extends StatelessWidget {
  const RouteResultCard({
    super.key,
    required this.route,
    required this.originLabel,
    required this.destinationLabel,
    required this.onModify,
    this.fastest = false,
    this.shortest = false,
  });

  final RouteResult route;
  final String originLabel;
  final String destinationLabel;
  final VoidCallback onModify;
  final bool fastest, shortest;

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
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: 560,
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
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
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: const Icon(Icons.directions_car_outlined, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ruta seleccionada',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (fastest || shortest)
            Wrap(
              spacing: 8,
              children: [
                if (fastest)
                  const Chip(
                    avatar: Icon(Icons.schedule, size: 16),
                    label: Text('Más rápida'),
                  ),
                if (shortest)
                  const Chip(
                    avatar: Icon(Icons.straighten, size: 16),
                    label: Text('Más corta'),
                  ),
              ],
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Wrap(
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
                  child: Text(
                    distance,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.trip_origin, size: 18, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  originLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Icon(
              Icons.arrow_downward,
              size: 16,
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: onModify,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Modificar ruta'),
              ),
              TextButton.icon(
                onPressed: () => _showDetails(context),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Ver detalles'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
