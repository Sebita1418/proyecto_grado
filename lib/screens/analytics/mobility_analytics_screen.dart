import 'package:flutter/material.dart';

import '../../controllers/mobility_analytics_controller.dart';
import '../../mobility/analytics/mobility_analytics.dart';
import '../../mobility/analytics/mobility_analytics_repository.dart';
import '../../services/supabase_mobility_analytics_repository.dart';
import '../../theme/mobility_theme.dart';

class MobilityAnalyticsScreen extends StatefulWidget {
  const MobilityAnalyticsScreen({super.key, this.repository, this.now});
  final MobilityAnalyticsRepository? repository;
  final DateTime Function()? now;
  @override
  State<MobilityAnalyticsScreen> createState() =>
      _MobilityAnalyticsScreenState();
}

class _MobilityAnalyticsScreenState extends State<MobilityAnalyticsScreen> {
  late final controller = MobilityAnalyticsController(
    widget.repository ?? SupabaseMobilityAnalyticsRepository(),
    now: widget.now,
  );
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String stamp(DateTime time) =>
      '${time.toIso8601String().substring(0, 16).replaceAll('T', ' ')} UTC';
  Widget card(String title, Widget child) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MobilityDesign.cardRadius),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
  Widget metric(String title, String value) => SizedBox(
    width: 260,
    child: card(
      title,
      Text(value, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
  Widget distribution(String label, int count, int total) {
    final proportion = total <= 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    final reports = '$count ${count == 1 ? 'reporte' : 'reportes'}';
    return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label · $reports (${(100 * proportion).toStringAsFixed(1)} %)',
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: proportion,
          semanticsLabel: '$label · $reports',
          semanticsValue: '${(100 * proportion).toStringAsFixed(1)}%',
        ),
      ],
    ),
  );
  }
  Widget coverage(MobilityAnalyticsSnapshot s) => card(
    'Cobertura de datos',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Periodo: ${stamp(s.query.start)} — ${stamp(s.query.end)} (fin exclusivo)',
        ),
        Text('Observaciones válidas: ${s.total}'),
        Text('Última actualización: ${stamp(s.updatedAt)}'),
        Text('Expirados: ${s.expired} · Cancelados: ${s.cancelled}'),
        Text(
          'Cobertura: ${s.availability == AnalyticsAvailability.partial ? 'Parcial' : 'Consulta completa'}',
        ),
        if (s.truncated)
          const Text(
            'Límite de 5000 observaciones alcanzado. Los indicadores describen solo la muestra recibida.',
          ),
        if (s.invalidRows > 0)
          Text('Registros excluidos por calidad: ${s.invalidRows}'),
        const Text('Fuente: reportes registrados en Transporte Inteligente.'),
      ],
    ),
  );
  Widget results(MobilityAnalyticsSnapshot s) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (s.availability == AnalyticsAvailability.partial)
        card(
          'Datos parciales',
          const Text('Los resultados no representan la totalidad del periodo.'),
        ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          metric('Reportes del periodo', '${s.total}'),
          metric('Reportes activos', '${s.active}'),
          metric(
            'Categoría más reportada',
            s.predominantCategory == null
                ? (s.total < 2 ? 'Datos insuficientes' : 'Empate')
                : analyticsCategories[s.predominantCategory]!,
          ),
          metric(
            'Mayor actividad de reportes',
            s.peakActivity.isEmpty
                ? 'Sin observaciones'
                : s.peakActivity.length > 1
                ? 'Empate entre ${s.peakActivity.length} franjas'
                : '${stamp(s.peakActivity.single.start)} — ${stamp(s.peakActivity.single.end)}',
          ),
        ],
      ),
      card(
        'Distribución por categoría',
        Column(
          children: [
            for (final entry in s.categories.entries)
              distribution(
                analyticsCategories[entry.key]!,
                entry.value,
                s.total,
              ),
          ],
        ),
      ),
      card(
        'Actividad temporal',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Franjas consecutivas desde el inicio del periodo, en UTC.',
            ),
            for (final bucket in s.temporal)
              distribution(
                '${stamp(bucket.start)} — ${stamp(bucket.end)}',
                bucket.count,
                s.total,
              ),
          ],
        ),
      ),
      coverage(s),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Analítica de movilidad')),
    body: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: const EdgeInsets.all(MobilityDesign.pageInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Indicadores construidos a partir de reportes de movilidad registrados.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final period in MobilityAnalyticsPeriod.values)
                        ChoiceChip(
                          label: Text(period.label),
                          selected: controller.period == period,
                          onSelected: (_) => controller.load(period),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  switch (controller.state) {
                    AnalyticsLoadState.idle ||
                    AnalyticsLoadState.loading => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    AnalyticsLoadState.error => card(
                      'Datos no disponibles',
                      Column(
                        children: [
                          const Text('No fue posible cargar la analítica.'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: controller.load,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                    AnalyticsLoadState.empty => Column(
                      children: [
                        card(
                          'Sin reportes',
                          const Text(
                            'No hay reportes registrados para este periodo.',
                          ),
                        ),
                        coverage(controller.snapshot!),
                      ],
                    ),
                    AnalyticsLoadState.data => results(controller.snapshot!),
                  },
                  const SizedBox(height: 16),
                  const Text(
                    'Los indicadores representan actividad de reportes y no el flujo total del tránsito.',
                  ),
                  const SizedBox(height: 12),
                  if (controller.state != AnalyticsLoadState.loading)
                    OutlinedButton(
                      onPressed: controller.load,
                      child: const Text('Actualizar'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
