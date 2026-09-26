import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Categories of road incidents and conditions for community reporting.
enum IncidentType {
  accident('Accidente', Icons.car_crash_outlined),
  congestion('Congestión', Icons.traffic_outlined),
  roadWork('Obra en la vía', Icons.construction_outlined),
  roadClosed('Vía cerrada', Icons.block_outlined),
  hazard('Peligro / Obstáculo', Icons.warning_amber_outlined),
  other('Otro', Icons.more_horiz_outlined);

  const IncidentType(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Clean draft contract for incident reports.
///
/// Prepares data for future persistence in the road-incident-reports increment
/// without fabricating coordinates or database records.
class IncidentReportDraft {
  const IncidentReportDraft({
    required this.type,
    this.coordinates,
    this.description,
  });

  final IncidentType type;
  final LatLng? coordinates;
  final String? description;
}

/// Bottom sheet modal to capture road incidents and hazards.
///
/// Designed to connect cleanly with the upcoming road-incident-reports backend.
/// Strictly enforces required type selection and handles location transparency.
class ReportIncidentSheet extends StatefulWidget {
  const ReportIncidentSheet({
    super.key,
    this.currentPosition,
    this.onSubmit,
    this.onChangeLocation,
  });

  final LatLng? currentPosition;
  final ValueChanged<IncidentReportDraft>? onSubmit;
  final VoidCallback? onChangeLocation;

  @override
  State<ReportIncidentSheet> createState() => _ReportIncidentSheetState();
}

class _ReportIncidentSheetState extends State<ReportIncidentSheet> {
  IncidentType? _selectedType;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final type = _selectedType;
    if (type == null) return;

    final descriptionText = _descriptionController.text.trim();
    final draft = IncidentReportDraft(
      type: type,
      coordinates: widget.currentPosition,
      description: descriptionText.isEmpty ? null : descriptionText,
    );

    widget.onSubmit?.call(draft);
    Navigator.of(context).pop(draft);
  }

  void _handleChangeLocation() {
    if (widget.onChangeLocation != null) {
      widget.onChangeLocation!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La selección manual de coordenadas se habilitará en el próximo incremento.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final position = widget.currentPosition;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Reportar novedad vial',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Informa novedades en la vía para la comunidad de movilidad.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Tipo de novedad *',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IncidentType.values.map((type) {
                  final isSelected = type == _selectedType;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label:
                        '${type.label}, ${isSelected ? 'seleccionado' : 'no seleccionado'}',
                    child: Material(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                ),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _selectedType = type),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type.icon,
                                size: 18,
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  type.label,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text(
                'Ubicación de la novedad',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        position != null
                            ? Icons.my_location
                            : Icons.location_off_outlined,
                        color: position != null
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            position != null
                                ? 'Ubicación actual detectada'
                                : 'Ubicación no disponible',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            position != null
                                ? '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}'
                                : 'Activa el GPS para asociar coordenadas exactas.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _handleChangeLocation,
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Descripción adicional (opcional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText:
                      'Detalles sobre la novedad (carril, sentido, etc.)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _selectedType == null ? null : _submit,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Enviar reporte'),
              ),
              const SizedBox(height: 8),
              Text(
                'Nota: La persistencia de novedades se conectará en el próximo incremento.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
