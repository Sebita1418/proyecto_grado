import 'package:flutter/material.dart';

import '../theme/mobility_theme.dart';

/// Map actions remain attached to the map and reuse the existing callbacks.
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

  Widget _surface(BuildContext context, Widget child) => Material(
    elevation: 5,
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MobilityDesign.cardRadius),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: .55),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _iconButton({
    Key? key,
    required String tooltip,
    required Widget icon,
    required VoidCallback? onPressed,
  }) => IconButton(
    key: key,
    constraints: const BoxConstraints.tightFor(
      width: MobilityDesign.controlSize,
      height: MobilityDesign.controlSize,
    ),
    tooltip: tooltip,
    onPressed: onPressed,
    icon: icon,
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final children = <Widget>[
      _surface(
        context,
        _iconButton(
          tooltip: 'Mi ubicaci\u00f3n',
          onPressed: locating ? null : onLocate,
          icon: locating
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.my_location_outlined, color: colors.primary),
        ),
      ),
      _surface(
        context,
        SizedBox(
          width: MobilityDesign.controlSize,
          height: MobilityDesign.controlSize,
          child: PopupMenuButton<String>(
            tooltip: 'Capas del mapa',
            icon: Icon(Icons.layers_outlined, color: colors.primary),
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
                child: const Text('Marcador de mi ubicaci\u00f3n'),
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
      ),
      if (onFitRoute != null)
        _surface(
          context,
          _iconButton(
            tooltip: 'Ver ruta completa',
            onPressed: onFitRoute,
            icon: Icon(Icons.fit_screen, color: colors.primary),
          ),
        ),
    ];
    final gap = horizontal
        ? const SizedBox(width: 8)
        : const SizedBox(height: 8);
    final grouped = Material(
      color: Colors.transparent,
      child: Flex(
        direction: horizontal ? Axis.horizontal : Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) gap,
            children[i],
          ],
        ],
      ),
    );
    final report = onReports == null
        ? null
        : _surface(
            context,
            _iconButton(
              key: const ValueKey('road-reports-control'),
              tooltip: reportsError
                  ? 'Reportes de la v\u00eda: revisar conexi\u00f3n'
                  : 'Consultar reportes de la v\u00eda',
              onPressed: onReports,
              icon: reportsLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Cargando reportes',
                      ),
                    )
                  : Icon(
                      reportsError
                          ? Icons.sync_problem
                          : Icons.campaign_outlined,
                      color: reportsError ? colors.error : colors.primary,
                    ),
            ),
          );
    if (report == null) return grouped;
    return Flex(
      direction: horizontal ? Axis.horizontal : Axis.vertical,
      mainAxisSize: MainAxisSize.min,
      children: [grouped, gap, report],
    );
  }
}
