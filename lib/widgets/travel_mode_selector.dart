import 'package:flutter/material.dart';

import '../mobility/transport_mode.dart';
import '../mobility/routing/routing_capabilities.dart';
import '../theme/mobility_theme.dart';

/// Extension providing display labels and icons
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
}

/// Selector for travel modes in the map experience.
///
/// Configured capabilities permit requests; received route snapshots determine
/// availability. Legacy callers without capabilities retain driving-only UI.
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
    this.capabilities,
    this.snapshot,
    this.enabled = true,
  });

  final TransportMode? selectedMode;
  final ValueChanged<TransportMode>? onModeSelected;
  final ValueChanged<TransportMode>? onUnavailableModeTap;
  final bool compact;
  final bool vehicleEvaluated;
  final bool scheduled;
  final bool vehicleAllowed;
  final bool analyzing;
  final RoutingCapabilities? capabilities;
  final MultimodalMobilitySnapshot? snapshot;
  final bool enabled;

  static const List<TransportMode> availableModes = TransportMode.values;

  /// Gaps and a responsive lower width for mode tiles.
  static const double spacing = 8;
  static const double tileMinWidth = 132;

  bool _isAvailable(TransportMode mode) =>
      (capabilities ?? RoutingCapabilities([TransportMode.driving])).supports(
        mode,
      ) &&
      (mode != TransportMode.driving || vehicleAllowed);

  void _handleTap(BuildContext context, TransportMode mode) {
    if (!enabled) return;
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
    return 2;
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
                    onSelected: (_) => _handleTap(context, mode),
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
            final isAvailable = _isAvailable(mode);

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
    if (capabilities != null) {
      if (!_isAvailable(mode)) {
        return mode == TransportMode.publicTransport
            ? 'Sin fuente de datos de transporte público integrada.'
            : mode == TransportMode.driving && !vehicleAllowed
            ? 'No disponible: no incluido en preferencias'
            : 'No disponible: sin proveedor integrado';
      }
      if (scheduled) return 'Referencia actual; sin predicción';
      if (analyzing && mode == selectedMode) return 'Consultando ruta';
      final summary = snapshot?.summaries[mode];
      if (summary?.availability == ModeAvailability.available) {
        return 'Disponible · ${(summary!.durationSeconds! / 60).ceil()} min · ${(summary.distanceMeters! / 1000).toStringAsFixed(1)} km';
      }
      if (summary?.availability == ModeAvailability.error) {
        return 'Error: ${summary!.reason}';
      }
      if (summary?.availability == ModeAvailability.unavailable) {
        return summary!.reason;
      }
      return 'Sin consultar: proveedor configurado';
    }
    if (mode == TransportMode.driving) {
      if (!vehicleAllowed) return 'No disponible: no incluido en preferencias';
      if (scheduled) return 'No disponible: sin datos horarios';
      if (analyzing) return 'Analizando rutas';
      return vehicleEvaluated ? 'Disponible ahora' : 'Disponible para analizar';
    }
    if (mode == TransportMode.publicTransport) {
      return 'No disponible todav\u00eda: datos no integrados';
    }
    return 'No disponible todav\u00eda: sin rutas integradas';
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
    final statusAvailable = status.startsWith('Disponible');
    final foreground = isSelected
        ? colorScheme.onPrimaryContainer
        : isAvailable
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MobilityDesign.controlRadius),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(MobilityDesign.controlRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: .07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      mode.icon,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mode.label,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusAvailable
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    height: 1.3,
                    color: statusAvailable
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
