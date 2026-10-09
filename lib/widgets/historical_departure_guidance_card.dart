import 'package:flutter/material.dart';

import '../controllers/historical_departure_guidance_controller.dart';
import '../mobility/analytics/historical_departure_guidance.dart';
import '../mobility/analytics/mobility_analytics_repository.dart';
import '../services/supabase_mobility_analytics_repository.dart';
import 'mobility_section_card.dart';

class HistoricalDepartureGuidanceCard extends StatefulWidget {
  const HistoricalDepartureGuidanceCard({
    super.key,
    required this.departure,
    this.repository,
    this.now,
  });
  final DateTime departure;
  final MobilityAnalyticsRepository? repository;
  final DateTime Function()? now;
  @override
  State<HistoricalDepartureGuidanceCard> createState() =>
      _HistoricalDepartureGuidanceCardState();
}

class _HistoricalDepartureGuidanceCardState
    extends State<HistoricalDepartureGuidanceCard> {
  late final controller = HistoricalDepartureGuidanceController(
    widget.repository ?? SupabaseMobilityAnalyticsRepository(),
    now: widget.now,
  );
  @override
  void initState() {
    super.initState();
    controller.load(widget.departure);
  }

  @override
  void didUpdateWidget(covariant HistoricalDepartureGuidanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.departure != widget.departure) {
      controller.load(widget.departure);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  static const weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];
  String hour(int value) => '${value.toString().padLeft(2, '0')}:00';
  Widget data(HistoricalDepartureGuidance result) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(result.reason, style: Theme.of(context).textTheme.titleSmall),
      if (result.status != HistoricalGuidanceStatus.observed &&
          result.reason != 'Datos insuficientes para orientar horarios')
        const Text('Datos insuficientes para orientar horarios'),
      Text(
        'Comparación histórica: ${weekdays[result.selectedWeekday - 1]} · franja seleccionada ${hour(result.selectedHour)}–${hour(result.selectedHour + 1)} · America/Bogota (UTC−05).',
      ),
      if (result.status == HistoricalGuidanceStatus.observed) ...[
        Text(
          'Franjas con menor actividad dentro de los ${weekdays[result.selectedWeekday - 1]} observados:',
        ),
        Text(
          '${result.lowerActivity.length} franja(s) con ${result.lowerActivity.first.observations} reportes / ${result.weekdayOccurrences} fechas cada una.',
        ),
        ExpansionTile(
          title: const Text('Ver franjas observadas'),
          children: [
            for (final metric in result.lowerActivity)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  '${hour(metric.hour)}–${hour(metric.hour + 1)} · ${metric.observations} reportes / ${metric.occurrences} fechas',
                ),
              ),
          ],
        ),
        Text(
          'Franja seleccionada: ${result.selectedMetric.observations} reportes / ${result.selectedMetric.occurrences} fechas.',
        ),
      ],
      Text(
        'Periodo consultado: ${BogotaCalendar.label(result.query.start)}–${BogotaCalendar.label(result.query.end)} (fin exclusivo). Días completos comparados: ${result.completeDays}; fechas del día de semana: ${result.weekdayOccurrences}.',
      ),
      Text(
        'Muestra: ${result.totalObservations} reportes del periodo; ${result.completeDayObservations} en días completos. Cobertura: ${result.status == HistoricalGuidanceStatus.partial ? 'parcial' : 'consulta completa de registros disponibles'}.',
      ),
      if (result.truncated)
        const Text('Consulta truncada: no se orientan horarios.'),
      if (result.excludedRows > 0)
        Text('Filas excluidas por calidad: ${result.excludedRows}.'),
      Text('Actualización: ${result.updatedAt.toUtc().toIso8601String()}'),
      const Text(
        'Fuente: reportes registrados en Transporte Inteligente. Historial general, sin relación geográfica con la ruta seleccionada.',
      ),
      OutlinedButton(
        onPressed: controller.retry,
        child: const Text('Actualizar historial'),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => MobilitySectionCard(
    title: 'Orientación histórica de horarios',
    icon: Icons.history_outlined,
    margin: const EdgeInsets.only(top: 12),
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (controller.state) {
            HistoricalGuidanceLoadState.idle ||
            HistoricalGuidanceLoadState.loading => const Column(
              children: [
                LinearProgressIndicator(),
                SizedBox(height: 8),
                Text('Cargando historial de reportes…'),
              ],
            ),
            HistoricalGuidanceLoadState.error => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Datos históricos no disponibles. No fue posible consultar el historial.',
                ),
                OutlinedButton(
                  onPressed: controller.retry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
            HistoricalGuidanceLoadState.data => data(controller.result!),
          },
          const SizedBox(height: 8),
          const Text(
            'Cero reportes no significa cero tráfico. Esta observación no predice condiciones futuras ni recomienda una hora óptima.',
          ),
        ],
      ),
    ),
  );
}
