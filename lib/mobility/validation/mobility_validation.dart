import '../vehicle_recommendation_policy.dart';

enum ValidationRuleStatus { pass, fail, notApplicable, unknown }

enum MobilityValidationStatus {
  consistent,
  inconsistent,
  incomplete,
  noRecommendation,
}

class ValidationRule {
  const ValidationRule(this.id, this.label, this.status, this.explanation);
  final String id, label, explanation;
  final ValidationRuleStatus status;
}

/// Minimal observed projection: no geometry, authors or individual reports.
class ValidationAlternative {
  const ValidationAlternative({
    required this.id,
    required this.providerOrder,
    required this.eligible,
    required this.seconds,
    required this.meters,
    this.source,
    this.reports,
    this.closures,
  });
  final String id;
  final int providerOrder;
  final bool eligible;
  final double seconds, meters;
  final String? source;
  final int? reports, closures;
  String get label => 'Alternativa ${providerOrder + 1}';
}

class ValidationReason {
  const ValidationReason(this.factor, this.explanation);
  final String factor, explanation;
}

class MobilityValidationInput {
  MobilityValidationInput({
    required Iterable<ValidationAlternative> alternatives,
    required this.suggestedId,
    required this.markedSuggestedId,
    required this.selectedId,
    required this.manuallySelected,
    required Iterable<ValidationReason> reasons,
    required Iterable<String> recommendationIds,
    this.suggestedSeconds,
    this.suggestedMeters,
    this.evaluatedAt,
  }) : alternatives = List.unmodifiable(alternatives),
       reasons = List.unmodifiable(reasons),
       recommendationIds = List.unmodifiable(recommendationIds) {
    if (this.alternatives.map((o) => o.id).toSet().length !=
            this.alternatives.length ||
        this.alternatives.map((o) => o.providerOrder).toSet().length !=
            this.alternatives.length ||
        this.alternatives.any(
          (o) =>
              !o.seconds.isFinite ||
              !o.meters.isFinite ||
              o.seconds < 0 ||
              o.meters < 0 ||
              o.providerOrder < 0 ||
              (o.reports != null && o.reports! < 0) ||
              (o.closures != null &&
                  (o.closures! < 0 ||
                      o.reports == null ||
                      o.closures! > o.reports!)),
        )) {
      throw ArgumentError('Invalid validation projection');
    }
  }
  final List<ValidationAlternative> alternatives;
  final List<ValidationReason> reasons;
  final List<String> recommendationIds;
  final String? suggestedId, markedSuggestedId, selectedId;
  final bool manuallySelected;
  final double? suggestedSeconds, suggestedMeters;
  final DateTime? evaluatedAt;
}

class MobilityValidationSnapshot {
  MobilityValidationSnapshot({
    required this.input,
    required this.status,
    required Iterable<ValidationRule> rules,
    required this.evaluatedCount,
    required this.comparableCount,
    required this.durationRank,
    required this.distanceRank,
    required this.extraDurationPercent,
    required this.extraDistancePercent,
    required this.consideredReports,
    required this.consideredClosures,
  }) : rules = List.unmodifiable(rules);
  final MobilityValidationInput input;
  final MobilityValidationStatus status;
  final List<ValidationRule> rules;
  final int evaluatedCount;
  final int? comparableCount,
      durationRank,
      distanceRank,
      consideredReports,
      consideredClosures;
  final double? extraDurationPercent, extraDistancePercent;
  ValidationAlternative? get suggested =>
      input.alternatives.where((o) => o.id == input.suggestedId).firstOrNull;
  ValidationAlternative? get selected =>
      input.alternatives.where((o) => o.id == input.selectedId).firstOrNull;
  bool? get suggestedIsSelected => suggested == null || selected == null
      ? null
      : suggested!.id == selected!.id;
}

/// Checks observed output against constraints; never chooses or mutates a route.
/// Rankings are technical comparisons, not a second recommendation.
class MobilityValidationEvaluator {
  const MobilityValidationEvaluator();
  MobilityValidationSnapshot evaluate(MobilityValidationInput input) {
    final eligible = input.alternatives.where((o) => o.eligible).toList()
      ..sort((a, b) => a.providerOrder.compareTo(b.providerOrder));
    final suggested = eligible
        .where((o) => o.id == input.suggestedId)
        .firstOrNull;
    final rules = <ValidationRule>[];
    void check(
      String id,
      String label,
      ValidationRuleStatus status,
      String explanation,
    ) => rules.add(ValidationRule(id, label, status, explanation));
    ValidationRuleStatus verdict(bool value) =>
        value ? ValidationRuleStatus.pass : ValidationRuleStatus.fail;
    final noRecommendation = input.suggestedId == null;
    check(
      'eligible',
      'Alternativa vehicular elegible',
      noRecommendation
          ? (eligible.isEmpty
                ? ValidationRuleStatus.notApplicable
                : ValidationRuleStatus.unknown)
          : verdict(suggested != null),
      noRecommendation
          ? (eligible.isEmpty
                ? 'No hubo alternativas elegibles para recomendación.'
                : 'Hay alternativas elegibles, pero no se recibió una recomendación; causa no evaluable aquí.')
          : 'La salida debe pertenecer a las alternativas vehiculares permitidas.',
    );
    check(
      'marked',
      'Sugerida coincide con la salida del motor',
      verdict(input.markedSuggestedId == input.suggestedId),
      'Compara la marca de presentación con la identidad de la salida observada.',
    );
    final allEvidence =
        eligible.isNotEmpty &&
        eligible.every((o) => o.reports != null && o.closures != null);
    check(
      'evidence',
      'Evidencia de incidentes disponible',
      eligible.isEmpty
          ? ValidationRuleStatus.notApplicable
          : allEvidence
          ? ValidationRuleStatus.pass
          : ValidationRuleStatus.unknown,
      allEvidence
          ? 'Snapshots coincidentes para todas las alternativas elegibles.'
          : 'Evidencia incompleta o desconocida; no equivale a cero reportes.',
    );
    final hasSelection = input.selectedId != null;
    check(
      'selection',
      'Selección conservada por separado',
      hasSelection
          ? verdict(input.alternatives.any((o) => o.id == input.selectedId))
          : ValidationRuleStatus.unknown,
      'Seleccionada y sugerida son campos distintos; una selección diferente no invalida la recomendación.',
    );

    int? comparableCount,
        durationRank,
        distanceRank,
        consideredReports,
        consideredClosures;
    double? extraDurationPercent, extraDistancePercent;
    if (eligible.isNotEmpty) {
      if (allEvidence) {
        // Counts are route/report proximities. A report near two routes counts twice.
        consideredReports = eligible.fold<int>(0, (n, o) => n + o.reports!);
        consideredClosures = eligible.fold<int>(0, (n, o) => n + o.closures!);
      }
      final fastestSeconds = eligible
          .map((o) => o.seconds)
          .reduce((a, b) => a < b ? a : b);
      final baselineMeters = eligible
          .where((o) => o.seconds == fastestSeconds)
          .map((o) => o.meters)
          .reduce((a, b) => a < b ? a : b);
      final minimumMeters = eligible
          .map((o) => o.meters)
          .reduce((a, b) => a < b ? a : b);
      var finalists = eligible;
      if (allEvidence) {
        final comparable = eligible
            .where(
              (o) =>
                  o.seconds <=
                      fastestSeconds *
                          VehicleRecommendationPolicy.comparableDurationRatio &&
                  o.meters <=
                      baselineMeters *
                          VehicleRecommendationPolicy.comparableDistanceRatio,
            )
            .toList();
        comparableCount = comparable.length;
        final withoutClosures = comparable
            .where((o) => o.closures == 0)
            .toList();
        final closureGroup = withoutClosures.isEmpty
            ? comparable
            : withoutClosures;
        final minReports = closureGroup
            .map((o) => o.reports!)
            .reduce((a, b) => a < b ? a : b);
        finalists = closureGroup.where((o) => o.reports == minReports).toList();
        check(
          'comparable',
          'Dentro del grupo comparable',
          suggested == null
              ? ValidationRuleStatus.unknown
              : verdict(comparable.any((o) => o.id == suggested.id)),
          'Hasta 25 % más de duración y 50 % más de distancia que la referencia más rápida (desempate por distancia).',
        );
        check(
          'closures',
          'Prioridad por ausencia de cierres',
          withoutClosures.isEmpty
              ? ValidationRuleStatus.notApplicable
              : suggested == null
              ? ValidationRuleStatus.unknown
              : verdict(withoutClosures.any((o) => o.id == suggested.id)),
          'Si hay alternativas comparables sin cierres, se excluyen las que tienen cierres.',
        );
        check(
          'reports',
          'Menor exposición entre comparables',
          suggested == null
              ? ValidationRuleStatus.unknown
              : verdict(finalists.any((o) => o.id == suggested.id)),
          'Mínimo de reportes próximos dentro del grupo con prioridad de cierres.',
        );
      } else {
        for (final entry in {
          'comparable': 'Dentro del grupo comparable',
          'closures': 'Prioridad por ausencia de cierres',
          'reports': 'Menor exposición entre comparables',
        }.entries) {
          check(
            entry.key,
            entry.value,
            ValidationRuleStatus.unknown,
            'No evaluable: el motor usa duración/distancia si falta un snapshot coincidente.',
          );
        }
      }
      final minSeconds = finalists
          .map((o) => o.seconds)
          .reduce((a, b) => a < b ? a : b);
      final durationTies = finalists
          .where((o) => o.seconds == minSeconds)
          .toList();
      final minTieMeters = durationTies
          .map((o) => o.meters)
          .reduce((a, b) => a < b ? a : b);
      final metricTies = durationTies
          .where((o) => o.meters == minTieMeters)
          .toList();
      check(
        'duration',
        'Duración mínima entre finalistas',
        suggested == null
            ? ValidationRuleStatus.unknown
            : finalists.length == 1
            ? ValidationRuleStatus.notApplicable
            : verdict(suggested.seconds == minSeconds),
        'La comparación se limita a finalistas; no asegura la ruta más rápida de todo el conjunto.',
      );
      check(
        'distance',
        'Distancia como desempate',
        suggested == null
            ? ValidationRuleStatus.unknown
            : durationTies.length < 2
            ? ValidationRuleStatus.notApplicable
            : verdict(
                suggested.seconds == minSeconds &&
                    suggested.meters == minTieMeters,
              ),
        'Menor distancia solo entre alternativas empatadas en duración.',
      );
      check(
        'providerOrder',
        'Orden estable del proveedor',
        suggested == null
            ? ValidationRuleStatus.unknown
            : metricTies.length < 2
            ? ValidationRuleStatus.notApplicable
            : verdict(suggested.id == metricTies.first.id),
        'Ante igual duración y distancia se conserva el primer orden original.',
      );
      check(
        'finalist',
        'Salida pertenece al grupo finalista',
        suggested == null
            ? ValidationRuleStatus.unknown
            : verdict(metricTies.any((o) => o.id == suggested.id)),
        'Comprueba restricciones de elegibilidad, exposición, duración y desempate sin reemplazar la decisión.',
      );
      if (suggested != null) {
        durationRank =
            1 + eligible.where((o) => o.seconds < suggested.seconds).length;
        distanceRank =
            1 + eligible.where((o) => o.meters < suggested.meters).length;
        double? difference(double value, double baseline) {
          if (baseline == 0) return value == 0 ? 0 : null;
          final percent = (value - baseline) / baseline * 100;
          return percent.isFinite ? percent : null;
        }

        extraDurationPercent = difference(suggested.seconds, fastestSeconds);
        extraDistancePercent = difference(suggested.meters, minimumMeters);
      }
      final ids = eligible.map((o) => o.id).toSet();
      check(
        'alternatives',
        'Conjunto evaluado completo',
        noRecommendation
            ? ValidationRuleStatus.unknown
            : verdict(
                input.recommendationIds.length == ids.length &&
                    input.recommendationIds.toSet().length == ids.length &&
                    input.recommendationIds.toSet().containsAll(ids),
              ),
        'La recomendación y sus alternativas deben conservar el conjunto elegible recibido.',
      );
    }
    if (!noRecommendation) {
      check(
        'metrics',
        'Métricas de salida coincidentes',
        suggested == null
            ? ValidationRuleStatus.unknown
            : verdict(
                input.suggestedSeconds == suggested.seconds &&
                    input.suggestedMeters == suggested.meters,
              ),
        'Contrasta duración y distancia de la salida con la alternativa original.',
      );
      for (var i = 0; i < input.reasons.length; i++) {
        final reason = input.reasons[i];
        ValidationRuleStatus status;
        switch (reason.factor) {
          case 'conditions':
            status = !allEvidence || suggested == null
                ? ValidationRuleStatus.unknown
                : rules.any(
                    (r) =>
                        ['comparable', 'closures', 'reports'].contains(r.id) &&
                        r.status == ValidationRuleStatus.fail,
                  )
                ? ValidationRuleStatus.fail
                : ValidationRuleStatus.pass;
            break;
          case 'duration':
            status =
                rules.where((r) => r.id == 'duration').firstOrNull?.status ??
                ValidationRuleStatus.unknown;
            break;
          case 'distance':
            status =
                rules.where((r) => r.id == 'distance').firstOrNull?.status ??
                ValidationRuleStatus.unknown;
            break;
          default:
            status = ValidationRuleStatus.unknown;
        }
        check(
          'reason-$i',
          'Respaldo del factor: ${reason.factor}',
          status,
          'Se verifica el factor contra datos observados. El texto libre no se certifica semánticamente.',
        );
      }
    }
    final failed = rules.any((r) => r.status == ValidationRuleStatus.fail);
    final unknown = rules.any((r) => r.status == ValidationRuleStatus.unknown);
    return MobilityValidationSnapshot(
      input: input,
      status: failed
          ? MobilityValidationStatus.inconsistent
          : noRecommendation
          ? MobilityValidationStatus.noRecommendation
          : unknown
          ? MobilityValidationStatus.incomplete
          : MobilityValidationStatus.consistent,
      rules: rules,
      evaluatedCount: noRecommendation ? 0 : eligible.length,
      comparableCount: comparableCount,
      durationRank: durationRank,
      distanceRank: distanceRank,
      extraDurationPercent: extraDurationPercent,
      extraDistancePercent: extraDistancePercent,
      consideredReports: consideredReports,
      consideredClosures: consideredClosures,
    );
  }
}
