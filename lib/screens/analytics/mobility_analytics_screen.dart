import 'package:flutter/material.dart';

import '../../controllers/mobility_analytics_controller.dart';
import '../../mobility/analytics/mobility_analytics.dart';
import '../../mobility/analytics/mobility_analytics_repository.dart';
import '../../services/supabase_mobility_analytics_repository.dart';
import '../../theme/mobility_theme.dart';
import '../../widgets/mobility_section_card.dart';
import '../../widgets/mobility_evidence_summary.dart';

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
  Widget card(String title, Widget child) =>
      MobilitySectionCard(title: title, child: child);
  Widget metric(String title, String value) =>
      card(title, Text(value, style: Theme.of(context).textTheme.titleLarge));
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
      MobilityEvidenceSummary(
        label: 'REPORTES OBSERVADOS',
        value: '${s.total}',
        detail:
            '${s.query.end.difference(s.query.start).inDays} días consultados',
        badge: s.availability == AnalyticsAvailability.partial
            ? 'Cobertura parcial'
            : 'Consulta completa',
      ),
      if (s.availability == AnalyticsAvailability.partial)
        card(
          'Datos parciales',
          const Text('Los resultados no representan la totalidad del periodo.'),
        ),
      card(
        'Actividad temporal',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Franjas consecutivas desde el inicio del periodo, en UTC.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height:
                  120 + 2 * MediaQuery.textScalerOf(context).scale(12) * 1.5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final bucket in s.temporal)
                    Expanded(
                      child: Tooltip(
                        message:
                            '${stamp(bucket.start)} — ${stamp(bucket.end)}: ${bucket.count} reportes',
                        child: Semantics(
                          label:
                              '${stamp(bucket.start)}: ${bucket.count} reportes',
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  height:
                                      (s.peakActivity.firstOrNull?.count ??
                                              0) ==
                                          0
                                      ? 1
                                      : 1 +
                                            100 *
                                                bucket.count /
                                                s.peakActivity.first.count,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF7AAAF5),
                                        MobilityDesign.brand,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${s.query.end.difference(s.query.start).inHours <= 24 ? bucket.start.hour : bucket.start.day}',
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ExpansionTile(
              title: const Text('Detalle temporal y cobertura'),
              children: [
                for (final bucket in s.temporal)
                  distribution(
                    '${stamp(bucket.start)} — ${stamp(bucket.end)}',
                    bucket.count,
                    s.total,
                  ),
              ],
            ),
          ],
        ),
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
      LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(14) > 18.2;
          final columns = constraints.maxWidth >= 900 && !largeText
              ? 4
              : constraints.maxWidth >= 600
              ? 2
              : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          final metrics = <Widget>[
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
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final item in metrics) SizedBox(width: width, child: item),
            ],
          );
        },
      ),
      coverage(s),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: MobilityDesign.appBarHeight(
        MediaQuery.textScalerOf(context),
      ),
      title: const Text('Analítica de movilidad', maxLines: 3),
    ),
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
