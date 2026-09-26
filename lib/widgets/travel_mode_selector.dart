import 'package:flutter/material.dart';

import '../mobility/transport_mode.dart';

/// Extension providing display labels, icons and availability
/// for [TransportMode] within presentation widgets.
extension TransportModeDisplay on TransportMode {
  String get label => switch (this) {
    TransportMode.driving => 'Vehículo',
    TransportMode.walking => 'A pie',
    TransportMode.cycling => 'Bicicleta',
    TransportMode.publicTransport => 'Transporte público',
  };

  IconData get icon => switch (this) {
    TransportMode.driving => Icons.directions_car_outlined,
    TransportMode.walking => Icons.directions_walk,
    TransportMode.cycling => Icons.directions_bike,
    TransportMode.publicTransport => Icons.directions_bus_outlined,
  };

  bool get isAvailable => this == TransportMode.driving;
}

/// Selector for travel modes in the map experience.
///
/// Only vehicular routing ([TransportMode.driving]) is productive in this
/// baseline. The other modes are displayed with an unmistakable
/// "Próximamente" badge so the roadmap stays honest without faking
/// multimodal routing.
///
/// The layout is a responsive grid: four tiles across when the available
/// width fits every label and badge without truncation, otherwise two
/// columns. Labels always keep their full text so nothing reads "Próx...".
class TravelModeSelector extends StatelessWidget {
  const TravelModeSelector({
    super.key,
    this.selectedMode = TransportMode.driving,
    this.onModeSelected,
    this.onUnavailableModeTap,
  });

  final TransportMode selectedMode;
  final ValueChanged<TransportMode>? onModeSelected;
  final ValueChanged<TransportMode>? onUnavailableModeTap;

  static const List<TransportMode> availableModes = TransportMode.values;

  /// Gap between tiles and the smallest tile width that keeps every label
  /// and the "Próximamente" badge legible at 1.5x text scale.
  static const double spacing = 8;
  static const double tileMinWidth = 132;

  void _handleTap(BuildContext context, TransportMode mode) {
    if (mode.isAvailable) {
      onModeSelected?.call(mode);
    } else {
      if (onUnavailableModeTap != null) {
        onUnavailableModeTap!(mode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El modo ${mode.label} estará disponible próximamente. '
              'Actualmente solo se calculan rutas vehiculares.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  int _columnsFor(double availableWidth) {
    final rowWidth =
        availableModes.length * tileMinWidth +
        (availableModes.length - 1) * spacing;
    return availableWidth >= rowWidth ? 4 : 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : availableModes.length * tileMinWidth +
                  (availableModes.length - 1) * spacing;
        final columns = _columnsFor(availableWidth);
        final tileWidth =
            (availableWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: availableModes.map((mode) {
            final isSelected = mode == selectedMode;
            final isAvailable = mode.isAvailable;

            final semanticsLabel = isAvailable
                ? '${mode.label}${isSelected ? ', seleccionado' : ''}'
                : '${mode.label}, Próximamente - no disponible';

            final tooltipMessage = isAvailable
                ? mode.label
                : '${mode.label} (Próximamente)';

            return SizedBox(
              width: tileWidth,
              child: Semantics(
                button: true,
                selected: isSelected,
                label: semanticsLabel,
                child: Tooltip(
                  message: tooltipMessage,
                  child: _TransportModeTile(
                    mode: mode,
                    isSelected: isSelected,
                    isAvailable: isAvailable,
                    onTap: () => _handleTap(context, mode),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Single presentation tile of [TravelModeSelector].
///
/// Selection and availability never rely on color alone: the selected tile
/// shows a thicker border plus the "Seleccionado" label, and unavailable
/// modes show the textual "Próximamente" badge.
class _TransportModeTile extends StatelessWidget {
  const _TransportModeTile({
    required this.mode,
    required this.isSelected,
    required this.isAvailable,
    required this.onTap,
  });

  final TransportMode mode;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = isSelected
        ? colorScheme.onPrimaryContainer
        : isAvailable
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(mode.icon, size: 20, color: foreground),
              const SizedBox(height: 4),
              Text(
                mode.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 4),
              if (isSelected)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 13,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'Seleccionado',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                )
              else if (!isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'Próximamente',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

