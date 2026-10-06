import 'package:flutter/material.dart';

import '../mobility/decision/departure_time_context.dart';
import '../theme/mobility_theme.dart';

class DepartureTimeSelector extends StatelessWidget {
  const DepartureTimeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final DepartureTimeContext value;
  final ValueChanged<DepartureTimeContext> onChanged;
  final bool enabled;

  Future<void> _schedule(BuildContext context) async {
    final now = DateTime.now();
    final initial = value.isScheduled && value.at.isAfter(now)
        ? value.at
        : now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateUtils.dateOnly(now),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: '¿Cuándo quieres salir?',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Hora de salida',
    );
    if (time == null || !context.mounted) return;
    final departure = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!departure.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige una fecha y hora futuras.')),
      );
      return;
    }
    onChanged(DepartureTimeContext.scheduled(departure));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¿Cuándo quieres salir?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.near_me_outlined, size: 18),
              label: const Text('Ahora'),
              selected: value.isNow,
              onSelected: enabled
                  ? (_) => onChanged(DepartureTimeContext.now(DateTime.now()))
                  : null,
            ),
            ChoiceChip(
              avatar: const Icon(Icons.schedule_outlined, size: 18),
              label: Text(value.isScheduled ? 'Cambiar horario' : 'Programar'),
              selected: value.isScheduled,
              onSelected: enabled ? (_) => _schedule(context) : null,
            ),
          ],
        ),
        if (value.isScheduled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(MobilityDesign.cardRadius),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.event_outlined, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${localizations.formatMediumDate(value.at)} · '
                    '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value.at), alwaysUse24HourFormat: true)}',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            container: true,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: MobilityDesign.warning),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planificación sin predicciones',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Aún no hay datos horarios para anticipar las condiciones. '
                          'La ruta calculada para Ahora no representa el tráfico futuro.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
