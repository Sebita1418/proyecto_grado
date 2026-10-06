import 'package:flutter/material.dart';

import '../../mobility/decision/departure_time_context.dart';

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
      helpText: 'Fecha de salida',
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
    final localizations = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Momento de salida',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
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
              avatar: const Icon(Icons.schedule, size: 18),
              label: const Text('Programar salida'),
              selected: value.isScheduled,
              onSelected: enabled ? (_) => _schedule(context) : null,
            ),
          ],
        ),
        if (value.isScheduled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Salida: ${localizations.formatMediumDate(value.at)} - '
              '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value.at), alwaysUse24HourFormat: true)}',
            ),
          ),
      ],
    );
  }
}
