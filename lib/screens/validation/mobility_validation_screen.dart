import 'package:flutter/material.dart';

import '../../mobility/validation/mobility_validation.dart';
import '../../theme/mobility_theme.dart';

class MobilityValidationScreen extends StatelessWidget {
  const MobilityValidationScreen({super.key, required this.snapshot});
  final MobilityValidationSnapshot snapshot;
  String count(int? n) => n == null ? 'Desconocido' : '$n';
  String percentage(double? value) => value == null
      ? 'No evaluable (referencia cero o datos ausentes)'
      : '${value.toStringAsFixed(1)} %';
  Widget section(BuildContext context, String title, List<Widget> children) =>
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MobilityDesign.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final suggested = s.suggested;
    final selected = s.selected;
    final status = switch (s.status) {
      MobilityValidationStatus.consistent => 'Reglas verificadas: consistentes',
      MobilityValidationStatus.inconsistent =>
        'Se encontraron criterios que no cumplen',
      MobilityValidationStatus.incomplete =>
        'Validación parcial: hay criterios no evaluables',
      MobilityValidationStatus.noRecommendation => 'Sin recomendación',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Validación de recomendación')),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.all(MobilityDesign.pageInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Recomendación determinista · Datos observados'),
                  section(context, 'Resumen', [
                    Text(status),
                    Text('Alternativas evaluadas: ${s.evaluatedCount}'),
                    Text(
                      'Alternativas recibidas: ${s.input.alternatives.length}',
                    ),
                    Text(
                      'Sugerida por el sistema: ${suggested?.label ?? 'No disponible'}',
                    ),
                    Text(
                      '${s.input.manuallySelected ? 'Seleccionada por el usuario' : 'Seleccionada en el flujo'}: ${selected?.label ?? 'No disponible'}',
                    ),
                    Text(
                      'Coincide con la sugerida: ${s.suggestedIsSelected == null
                          ? 'No evaluable'
                          : s.suggestedIsSelected!
                          ? 'Sí'
                          : 'No'}',
                    ),
                    if (suggested != null) ...[
                      Text(
                        'Duración sugerida: ${(suggested.seconds / 60).toStringAsFixed(1)} min',
                      ),
                      Text(
                        'Distancia sugerida: ${(suggested.meters / 1000).toStringAsFixed(1)} km',
                      ),
                    ],
                    if (s.input.evaluatedAt != null)
                      Text(
                        'Evaluación del motor: ${s.input.evaluatedAt!.toUtc().toIso8601String()}',
                      ),
                  ]),
                  section(context, 'Criterios evaluados', [
                    for (final rule in s.rules)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${switch (rule.status) {
                                ValidationRuleStatus.pass => '✓ Cumple',
                                ValidationRuleStatus.fail => '× No cumple',
                                ValidationRuleStatus.unknown => '! No evaluable',
                                ValidationRuleStatus.notApplicable => '— No aplica',
                              }} · ${rule.label}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(rule.explanation),
                          ],
                        ),
                      ),
                  ]),
                  section(context, 'Comparación', [
                    Text('Posición por duración: ${count(s.durationRank)}'),
                    Text('Posición por distancia: ${count(s.distanceRank)}'),
                    Text(
                      'Diferencia frente a la más rápida: ${percentage(s.extraDurationPercent)}',
                    ),
                    Text(
                      'Diferencia frente a la más corta: ${percentage(s.extraDistancePercent)}',
                    ),
                    Text(
                      'Alternativas comparables por evidencia: ${count(s.comparableCount)}',
                    ),
                    const Text(
                      'Rankings con empates: 1 + número de alternativas estrictamente mejores. Estimaciones del proveedor sin ajustes.',
                    ),
                  ]),
                  section(context, 'Evidencia disponible', [
                    Text(
                      'Proveedor de ruta sugerida: ${suggested?.source ?? 'Desconocido'}',
                    ),
                    Text(
                      'Reportes próximos en la sugerida: ${count(suggested?.reports)}',
                    ),
                    Text(
                      'Cierres próximos en la sugerida: ${count(suggested?.closures)}',
                    ),
                    Text(
                      'Proximidades consideradas: ${count(s.consideredReports)}',
                    ),
                    Text(
                      'Proximidades de cierres consideradas: ${count(s.consideredClosures)}',
                    ),
                    const Text(
                      'Fuente: snapshots de reportes viales activos ya disponibles en el cálculo. Una observación próxima a varias rutas cuenta por cada ruta; no son reportes únicos.',
                    ),
                    const Text(
                      'Proximidad no confirma bloqueo, retraso ni flujo vehicular. Desconocido no significa ausencia.',
                    ),
                  ]),
                  section(context, 'Razones de recomendación', [
                    if (s.input.reasons.isEmpty)
                      const Text(
                        'No hay razones de recomendación disponibles.',
                      ),
                    for (final reason in s.input.reasons)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(reason.explanation),
                      ),
                    const Text(
                      'Se comprueba el respaldo del factor; el texto libre no se certifica automáticamente.',
                    ),
                  ]),
                  const Text(
                    'Esta vista observa el resultado capturado al abrirla. No cambia la ruta seleccionada ni vuelve a calcular la recomendación.',
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
