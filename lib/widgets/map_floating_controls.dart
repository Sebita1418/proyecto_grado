import 'package:flutter/material.dart';

/// Only toggles overlays that already exist; the OSM base map stays unchanged.
class MapFloatingControls extends StatelessWidget {
  const MapFloatingControls({
    super.key,
    required this.locating,
    required this.onLocate,
    required this.showPosition,
    required this.onShowPosition,
    required this.showRoute,
    required this.onShowRoute,
    this.onFitRoute,
    this.horizontal = false,
    this.onReports,
    this.reportsLoading = false,
    this.reportsError = false,
  });

  final bool locating, showPosition, showRoute;
  final bool horizontal;
  final VoidCallback? onReports;
  final bool reportsLoading, reportsError;
  final VoidCallback onLocate;
  final VoidCallback? onFitRoute;
  final ValueChanged<bool> onShowPosition, onShowRoute;

  @override
  Widget build(BuildContext context) => Flex(
    direction: horizontal ? Axis.horizontal : Axis.vertical,
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      FloatingActionButton(
        mini: true,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        elevation: 3,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        heroTag: 'current-location',
        tooltip: 'Mi ubicación',
        onPressed: locating ? null : onLocate,
        child: locating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
      ),
      const SizedBox(height: 4, width: 4),
      Material(
        elevation: 3,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: PopupMenuButton<String>(
          tooltip: 'Capas del mapa',
          icon: const Icon(Icons.layers_outlined),
          onSelected: (value) {
            if (value == 'position') onShowPosition(!showPosition);
            if (value == 'route') onShowRoute(!showRoute);
          },
          itemBuilder: (_) => [
            const PopupMenuItem<String>(
              enabled: false,
              child: Text('Mapa base: OpenStreetMap'),
            ),
            CheckedPopupMenuItem(
              value: 'position',
              checked: showPosition,
              child: const Text('Marcador de mi ubicación'),
            ),
            if (onFitRoute != null)
              CheckedPopupMenuItem(
                value: 'route',
                checked: showRoute,
                child: const Text('Ruta calculada'),
              ),
          ],
        ),
      ),
      if (onFitRoute != null) ...[
        const SizedBox(height: 4, width: 4),
        FloatingActionButton(
          mini: true,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          elevation: 3,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          heroTag: 'full-route',
          tooltip: 'Ver ruta completa',
          onPressed: onFitRoute,
          child: const Icon(Icons.fit_screen),
        ),
      ],
      if (onReports != null) ...[
        const SizedBox(height: 4, width: 4),
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(16),
          child: IconButton(
            tooltip: reportsError ? 'Reportes de la vía: revisar conexión' : 'Reportes de la vía',
            onPressed: onReports,
            icon: reportsLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Cargando reportes'))
                : Icon(reportsError ? Icons.sync_problem : Icons.report_outlined),
          ),
        ),
      ],
    ],
  );
}
