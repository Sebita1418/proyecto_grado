import 'package:flutter/material.dart';

enum RouteStatusType { initial, loading, error }

class RouteStatus extends StatelessWidget {
  const RouteStatus({super.key, required this.type, this.message});

  final RouteStatusType type;
  final String? message;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case RouteStatusType.initial:
        return _buildStatus(
          context: context,
          icon: Icons.route_outlined,
          title: 'Planifica tu recorrido',
          message:
              message ??
              'Ingresa un punto de origen y un destino para calcular tu ruta.',
        );

      case RouteStatusType.loading:
        return _buildLoadingStatus(context);

      case RouteStatusType.error:
        return _buildStatus(
          context: context,
          icon: Icons.error_outline,
          title: 'No fue posible calcular la ruta',
          message:
              message ??
              'Ocurrió un problema al consultar la ruta. Intenta nuevamente.',
        );
    }
  }

  Widget _buildLoadingStatus(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Calculando ruta',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculando ruta',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message ?? 'Estamos buscando la mejor ruta disponible.',
                      style: theme.textTheme.bodyMedium,
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

  Widget _buildStatus({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
