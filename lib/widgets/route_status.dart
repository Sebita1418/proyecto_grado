import 'package:flutter/material.dart';

enum RouteStatusType { idle, loading, error }

class RouteStatus extends StatelessWidget {
  const RouteStatus({super.key, required this.status, this.message});

  final RouteStatusType status;
  final String? message;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case RouteStatusType.idle:
        return _StatusContainer(
          icon: Icons.route_outlined,
          title: 'Consulta una ruta',
          message:
              message ??
              'Ingresa un origen y un destino para calcular tu ruta.',
        );

      case RouteStatusType.loading:
        return _StatusContainer(
          title: 'Calculando ruta',
          message:
              message ??
              'Estamos buscando la mejor ruta disponible. Espera un momento.',
          child: const CircularProgressIndicator(),
        );

      case RouteStatusType.error:
        return _StatusContainer(
          icon: Icons.error_outline,
          title: 'No fue posible calcular la ruta',
          message:
              message ??
              'Ocurrió un problema al consultar la ruta. Inténtalo nuevamente.',
        );
    }
  }
}

class _StatusContainer extends StatelessWidget {
  const _StatusContainer({
    required this.title,
    required this.message,
    this.icon,
    this.child,
  });

  final String title;
  final String message;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (child != null)
              child!
            else if (icon != null)
              Icon(icon, size: 36, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
