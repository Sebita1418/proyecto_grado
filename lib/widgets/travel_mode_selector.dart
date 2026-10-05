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
/// baseline. Other modes state which provider evidence is missing.
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
    this.compact = false,
    this.vehicleEvaluated = false,
    this.scheduled = false,
    this.vehicleAllowed = true,
    this.analyzing = false,
  });

  final TransportMode? selectedMode;
  final ValueChanged<TransportMode>? onModeSelected;
  final ValueChanged<TransportMode>? onUnavailableModeTap;
  final bool compact;
  final bool vehicleEvaluated;
  final bool scheduled;
  final bool vehicleAllowed;
  final bool analyzing;

  static const List<TransportMode> availableModes = TransportMode.values;

  /// Gaps and a responsive lower width for mode tiles.
  static const double spacing = 8;
  static const double tileMinWidth = 132;

  bool _isAvailable(TransportMode mode) =>
      mode.isAvailable && (mode != TransportMode.driving || vehicleAllowed);

  void _handleTap(BuildContext context, TransportMode mode) {
    if (_isAvailable(mode)) {
      onModeSelected?.call(mode);
    } else {
      if (onUnavailableModeTap != null) {
        onUnavailableModeTap!(mode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mode == TransportMode.driving
                  ? 'El vehículo no está incluido en tus preferencias.'
                  : mode == TransportMode.publicTransport
                  ? 'Aún no hay datos integrados de transporte público.'
                  : 'Aún no hay rutas disponibles para ${mode.label.toLowerCase()}.',
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
    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final mode in availableModes)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: '${mode.label}: ${_status(mode)}',
                  child: ChoiceChip(
                    avatar: Icon(mode.icon, size: 18),
                    label: Text(mode.label),
                    selected: mode == selectedMode,
                    onSelected: _isAvailable(mode)
                        ? (_) => _handleTap(context, mode)
                        : null,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : availableModes.length * tileMinWidth +
                  (availableModes.length - 1) * spacing;
        final columns = _columnsFor(availableWidth);
        final tileWidth = (availableWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: availableModes.map((mode) {
            final isSelected = mode == selectedMode;
            final isAvailable =
                mode.isAvailable &&
                (mode != TransportMode.driving || vehicleAllowed);

            final status = _status(mode);
            final semanticsLabel =
                '${mode.label}, $status'
                '${isSelected ? ', seleccionado' : ''}';

            return SizedBox(
              width: tileWidth,
              child: Semantics(
                button: true,
                selected: isSelected,
                label: semanticsLabel,
                child: Tooltip(
                  message: semanticsLabel,
                  child: _TransportModeTile(
                    mode: mode,
                    isSelected: isSelected,
                    isAvailable: isAvailable,
                    status: status,
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

  String _status(TransportMode mode) {
    if (mode == TransportMode.driving) {
      if (!vehicleAllowed) return 'No incluido en preferencias';
      if (scheduled) return 'Sin datos horarios';
      if (analyzing) return 'Analizando rutas';
      return vehicleEvaluated ? 'Disponible' : 'Se evalúa al analizar';
    }
    if (mode == TransportMode.publicTransport) return 'Datos no integrados';
    return 'Sin rutas disponibles';
  }
}

/// Single presentation tile of [TravelModeSelector].
///
/// Selection and availability never rely on color alone: the selected tile
/// shows a check and every mode carries a short evidence status.
class _TransportModeTile extends StatelessWidget {
  const _TransportModeTile({
    required this.mode,
    required this.isSelected,
    required this.isAvailable,
    required this.status,
    required this.onTap,
  });

  final TransportMode mode;
  final bool isSelected;
  final bool isAvailable;
  final String status;
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
                Icon(
                  Icons.check_circle_outline,
                  size: 15,
                  color: colorScheme.primary,
                ),
              if (isSelected) const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isAvailable && !status.startsWith('Sin ')
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: isAvailable && !status.startsWith('Sin ')
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
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
