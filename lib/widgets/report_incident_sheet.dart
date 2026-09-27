import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/incident_report_draft.dart';
import '../models/road_incident_report.dart';
export '../models/incident_report_draft.dart';

/// Bottom sheet modal to capture road incidents and hazards.
///
/// Publishes through the injected callback, or preserves a local draft offline.
/// Strictly enforces required type selection and handles location transparency.
class ReportIncidentSheet extends StatefulWidget {
  const ReportIncidentSheet({
    super.key,
    this.currentPosition,
    this.onSubmit,
    this.onPublish,
    this.onChangeLocation,
    this.onPickLocation,
    this.initialDraft,
    this.onDraftChanged,
  });

  final LatLng? currentPosition;
  final ValueChanged<IncidentReportDraft>? onSubmit;
  final Future<void> Function(IncidentReportDraft draft)? onPublish;
  final VoidCallback? onChangeLocation;
  final Future<LatLng?> Function(LatLng? current)? onPickLocation;
  final IncidentReportDraft? initialDraft;
  final ValueChanged<IncidentReportDraft>? onDraftChanged;

  @override
  State<ReportIncidentSheet> createState() => _ReportIncidentSheetState();
}

class _ReportIncidentSheetState extends State<ReportIncidentSheet> {
  IncidentType? _selectedType;
  final TextEditingController _descriptionController = TextEditingController();
  LatLng? _coordinates;
  bool _manualLocation = false;
  bool _picking = false;
  bool _publishing = false;
  String? _publishError;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialDraft?.type;
    _coordinates = widget.initialDraft?.coordinates ?? widget.currentPosition;
    _manualLocation = widget.initialDraft?.manualLocation ?? false;
    _descriptionController.text = widget.initialDraft?.description ?? '';
    _descriptionController.addListener(_saveDraft);
  }

  IncidentReportDraft get _draft => IncidentReportDraft(
    type: _selectedType,
    coordinates: _coordinates,
    description: _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim(),
    manualLocation: _manualLocation,
  );

  void _saveDraft() => widget.onDraftChanged?.call(_draft);

  @override
  void didUpdateWidget(covariant ReportIncidentSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_manualLocation &&
        widget.initialDraft == null &&
        oldWidget.currentPosition != widget.currentPosition) {
      _coordinates = widget.currentPosition;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedType == null ||
        _coordinates == null ||
        _picking ||
        _publishing ||
        !RoadIncidentReport.validCoordinates(_coordinates!)) {
      return;
    }
    final draft = _draft;
    if (widget.onPublish == null) {
      widget.onSubmit?.call(draft);
      Navigator.of(context).pop(draft);
      return;
    }
    setState(() {
      _publishing = true;
      _publishError = null;
    });
    try {
      await widget.onPublish!(draft);
      if (!mounted) return;
      setState(() => _publishing = false);
      Navigator.of(context).pop(draft);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _publishing = false;
        _publishError =
            'No fue posible publicar el reporte. Intenta nuevamente.';
      });
    }
  }

  Future<void> _handleChangeLocation() async {
    if (_picking) return;
    if (widget.onPickLocation == null) {
      widget.onChangeLocation?.call();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _picking = true);
    try {
      final point = await widget.onPickLocation!(_coordinates);
      if (!mounted || point == null) return;
      setState(() {
        _coordinates = point;
        _manualLocation = true;
      });
      _saveDraft();
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final position = _coordinates;

    return PopScope(
      canPop: !_publishing,
      child: AbsorbPointer(
        absorbing: _publishing,
        child: SafeArea(
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
                                'Reportar novedad',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.onPublish == null
                                  ? 'Prepara un borrador con lo que observaste en la vía.'
                                  : 'Comparte lo que observaste en la vía.',
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
                  LayoutBuilder(builder: (context, constraints) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: IncidentType.values.map((type) {
                      final isSelected = type == _selectedType;
                      return SizedBox(
                        width: (constraints.maxWidth - 8) / 2,
                        child: Semantics(
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
                            onTap: () {
                              setState(() => _selectedType = type);
                              _saveDraft();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
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
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
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
                      ));
                    }).toList(),
                  )),
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
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
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
                                    ? _manualLocation
                                          ? 'Ubicación elegida en el mapa'
                                          : 'Tu ubicación actual'
                                    : 'Ubicación no disponible',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                position != null
                                    ? '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}'
                                    : 'Selecciona un punto en el mapa o activa el GPS.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed:
                          _picking ||
                              (widget.onPickLocation == null &&
                                  widget.onChangeLocation == null)
                          ? null
                          : _handleChangeLocation,
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: const Text('Cambiar ubicación'),
                    ),
                  ),
                  if (_manualLocation && widget.currentPosition != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _picking ? null : () {
                          setState(() {
                            _coordinates = widget.currentPosition;
                            _manualLocation = false;
                          });
                          _saveDraft();
                        },
                        icon: const Icon(Icons.my_location),
                        label: const Text('Usar mi ubicación actual'),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Descripción (opcional)',
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
                      labelText: 'Descripción (opcional)',
                      hintText: 'Detalles sobre la novedad (carril, sentido, etc.)...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_publishError != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _publishError!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed:
                        _selectedType == null ||
                            position == null ||
                            _picking ||
                            _publishing ||
                            !RoadIncidentReport.validCoordinates(position)
                        ? null
                        : _submit,
                    icon: _publishing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            widget.onPublish == null
                                ? Icons.drafts_outlined
                                : Icons.send_outlined,
                          ),
                    label: Text(
                      _publishing
                          ? 'Publicando…'
                          : widget.onPublish == null
                          ? 'Preparar reporte'
                          : 'Publicar reporte',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.onPublish == null
                        ? 'Envío de reportes pendiente de habilitación. El borrador se conserva solo mientras permanezcas en este mapa.'
                        : 'El reporte será visible para otros usuarios durante seis horas.',
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
        ),
      ),
    );
  }
}
