import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/mobility_recommendation.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/route_incident_analysis.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_policy.dart';
import 'package:transporte_inteligente/mobility/validation/current_mobility_validation_adapter.dart';
import 'package:transporte_inteligente/mobility/validation/mobility_validation.dart';
import 'package:transporte_inteligente/models/route_result.dart';
import 'package:transporte_inteligente/models/road_incident_report.dart';
import 'package:transporte_inteligente/models/incident_report_draft.dart';

const origin = LatLng(7.1, -73.1), destination = LatLng(7.2, -73.2);
final instant = DateTime.utc(2026, 10, 7, 12);
RouteOption option(
  String id,
  double seconds,
  double meters, {
  TransportMode mode = TransportMode.driving,
}) => RouteOption.fromRouteResult(
  id: id,
  mode: mode,
  source: 'osrm',
  route: RouteResult(
    origin: origin,
    destination: destination,
    points: const [origin, destination],
    durationSeconds: seconds,
    distanceMeters: meters,
  ),
);
RouteIncidentAnalysis analysis(String id, int reports, {int closures = 0}) =>
    RouteIncidentAnalysis(
      routeId: id,
      evaluatedAt: instant,
      incidents: List.generate(
        reports,
        (i) => RouteIncidentProximity(
          RoadIncidentReport(
            id: '$id-$i',
            userId: 'test-only',
            coordinates: origin,
            type: i < closures ? IncidentType.roadClosed : IncidentType.hazard,
            createdAt: instant.subtract(const Duration(hours: 1)),
            expiresAt: instant.add(const Duration(hours: 1)),
            status: 'activo',
          ),
          10,
        ),
      ),
    );
MobilityContext context({
  List<RouteIncidentAnalysis> analyses = const [],
  Set<TransportMode> modes = const {TransportMode.driving},
}) => MobilityContext(
  origin: origin,
  destination: destination,
  allowedModes: modes,
  requestedAt: instant,
  incidentAnalyses: {for (final a in analyses) a.routeId: a},
);
MobilityValidationInput project(
  MobilityContext trip,
  List<RouteOption> options,
  MobilityRecommendation? recommendation, {
  String? selected,
  String? marked,
  bool manual = false,
}) => const CurrentMobilityValidationAdapter().build(
  context: trip,
  options: options,
  recommendation: recommendation,
  markedSuggestedId: marked ?? recommendation?.recommended.id,
  selectedId: selected ?? recommendation?.recommended.id,
  manuallySelected: manual,
);
Future<MobilityValidationSnapshot> evaluate(
  List<RouteOption> options,
  MobilityContext trip, {
  String? selected,
  bool manual = false,
}) async {
  final recommendation = await VehicleRecommendationEngine(clock: () => instant)
      .recommend(trip, options);
  return const MobilityValidationEvaluator().evaluate(
    project(trip, options, recommendation, selected: selected, manual: manual),
  );
}

ValidationRule rule(MobilityValidationSnapshot s, String id) =>
    s.rules.firstWhere((r) => r.id == id);

void main() {
  test('extracted bounds preserve public engine constants', () {
    expect(VehicleRecommendationEngine.comparableDurationRatio, 1.25);
    expect(VehicleRecommendationEngine.comparableDistanceRatio, 1.5);
    expect(
      VehicleRecommendationPolicy.comparableDurationRatio,
      VehicleRecommendationEngine.comparableDurationRatio,
    );
  });
  test(
    'one alternative, known zero, ranks, safe percentages, immutable',
    () async {
      final s = await evaluate([
        option('a', 0, 0),
      ], context(analyses: [analysis('a', 0)]));
      expect(
        s.status,
        MobilityValidationStatus.incomplete,
      ); // Free-form other reason remains unknown.
      expect(s.evaluatedCount, 1);
      expect(s.comparableCount, 1);
      expect([s.durationRank, s.distanceRank], [1, 1]);
      expect([s.extraDurationPercent, s.extraDistancePercent], [0, 0]);
      expect(rule(s, 'duration').status, ValidationRuleStatus.notApplicable);
      expect(s.suggested!.reports, 0);
      expect(() => s.rules.clear(), throwsUnsupportedError);
      expect(() => s.input.alternatives.clear(), throwsUnsupportedError);
      expect(() => s.input.reasons.clear(), throwsUnsupportedError);
    },
  );
  test(
    'fastest but not shortest with unknown conditions retains UNKNOWN',
    () async {
      final s = await evaluate([
        option('a', 100, 2000),
        option('b', 120, 1000),
      ], context());
      expect(s.suggested!.id, 'a');
      expect([s.durationRank, s.distanceRank], [1, 2]);
      expect(s.extraDistancePercent, 100);
      expect(s.suggested!.reports, isNull);
      expect(s.consideredReports, isNull);
      expect(rule(s, 'evidence').status, ValidationRuleStatus.unknown);
      expect(rule(s, 'closures').status, ValidationRuleStatus.unknown);
      expect(rule(s, 'duration').status, ValidationRuleStatus.pass);
      expect(s.status, MobilityValidationStatus.incomplete);
    },
  );
  test('closure priority suggests slower shortest option; real differences and manual selection', () async {
    final s = await evaluate(
      [option('a', 100, 1000), option('b', 120, 800)],
      context(analyses: [analysis('a', 1, closures: 1), analysis('b', 0)]),
      selected: 'a',
      manual: true,
    );
    expect(s.suggested!.id, 'b');
    expect(s.selected!.id, 'a');
    expect(s.suggestedIsSelected, isFalse);
    expect(s.input.manuallySelected, isTrue);
    expect([s.durationRank, s.distanceRank], [2, 1]);
    expect(s.extraDurationPercent, closeTo(20, 1e-10));
    expect(s.extraDistancePercent, 0);
    expect([s.consideredReports, s.consideredClosures], [1, 1]);
    expect(rule(s, 'closures').status, ValidationRuleStatus.pass);
    expect(rule(s, 'selection').status, ValidationRuleStatus.pass);
    expect(
      s.rules.where((r) => r.status == ValidationRuleStatus.fail),
      isEmpty,
    );
  });
  test(
    'fewer reports within exact bounds, excludes outside despite zero reports',
    () async {
      final options = [
        option('a', 100, 1000),
        option('b', 125, 1500),
        option('c', 126, 900),
      ];
      final s = await evaluate(
        options,
        context(
          analyses: [analysis('a', 3), analysis('b', 1), analysis('c', 0)],
        ),
      );
      expect(s.suggested!.id, 'b');
      expect(s.comparableCount, 2);
      expect(s.extraDurationPercent, 25);
      expect(s.extraDistancePercent, closeTo(100 * 600 / 900, 1e-10));
      expect(rule(s, 'reports').status, ValidationRuleStatus.pass);
    },
  );
  test(
    'ties preserve provider order and distance tie-break; engine consistency',
    () async {
      for (final options in [
        [option('b', 100, 1000), option('a', 100, 1000)],
        [option('a', 100, 1000), option('b', 100, 1000)],
        [option('a', 100, 1500), option('b', 100, 1000)],
      ]) {
        final trip = context(
          analyses: options.map((o) => analysis(o.id, 0)).toList(),
        );
        final s = await evaluate(options, trip);
        expect(
          s.suggested!.id,
          options.last.route.distanceMeters < options.first.route.distanceMeters
              ? options.last.id
              : options.first.id,
        );
        expect(
          s.rules.where((r) => r.status == ValidationRuleStatus.fail),
          isEmpty,
        );
        expect([s.durationRank, s.distanceRank], [1, 1]);
      }
    },
  );
  test('consistency matrix runs productive engine then independently checks all stages', () async {
    final options = [
      option('a', 100, 1000),
      option('b', 115, 1100),
      option('c', 130, 900),
    ];
    for (final reports in [
      [0, 0, 0],
      [2, 0, 1],
      [1, 2, 0],
    ]) {
      for (final closures in [false, true]) {
        final s = await evaluate(
          options,
          context(
            analyses: [
              for (var i = 0; i < options.length; i++)
                analysis(
                  options[i].id,
                  reports[i],
                  closures: closures && i == 0 && reports[i] > 0 ? 1 : 0,
                ),
            ],
          ),
        );
        expect(
          s.rules.where((r) => r.status == ValidationRuleStatus.fail),
          isEmpty,
        );
        expect(rule(s, 'finalist').status, ValidationRuleStatus.pass);
        expect(rule(s, 'comparable').status, ValidationRuleStatus.pass);
      }
    }
  });
  test(
    'all closures is not applicable avoidance, still minimizes reports',
    () async {
      final s = await evaluate(
        [option('a', 100, 1000), option('b', 110, 1000)],
        context(
          analyses: [
            analysis('a', 2, closures: 1),
            analysis('b', 1, closures: 1),
          ],
        ),
      );
      expect(s.suggested!.id, 'b');
      expect(rule(s, 'closures').status, ValidationRuleStatus.notApplicable);
      expect(rule(s, 'reports').status, ValidationRuleStatus.pass);
    },
  );
  test(
    'missing/mismatched incident snapshot never becomes favorable zero',
    () async {
      final options = [option('a', 100, 1000), option('b', 110, 1000)];
      for (final trip in [
        context(analyses: [analysis('a', 0)]),
        MobilityContext(
          origin: origin,
          destination: destination,
          allowedModes: {TransportMode.driving},
          requestedAt: instant,
          incidentAnalyses: {
            'a': analysis('different-id', 0),
            'b': analysis('b', 0),
          },
        ),
      ]) {
        final s = await evaluate(options, trip);
        expect(s.suggested!.id, 'a');
        expect(s.consideredReports, isNull);
        expect(s.consideredClosures, isNull);
        expect(rule(s, 'reports').status, ValidationRuleStatus.unknown);
      }
    },
  );
  test('known reports with one unknown closure keeps aggregate evidence unknown', () {
    final input = MobilityValidationInput(
      alternatives: const [
        ValidationAlternative(id: 'a', providerOrder: 0, eligible: true,
          seconds: 100, meters: 1000, reports: 2, closures: 1),
        ValidationAlternative(id: 'b', providerOrder: 1, eligible: true,
          seconds: 110, meters: 1000, reports: 3),
      ],
      suggestedId: 'a', markedSuggestedId: 'a', selectedId: 'a',
      manuallySelected: false, reasons: const [], recommendationIds: const ['a', 'b'],
      suggestedSeconds: 100, suggestedMeters: 1000,
    );
    final s = const MobilityValidationEvaluator().evaluate(input);
    expect(s.consideredClosures, isNull);
    expect(s.consideredReports, isNull); // Aggregates require complete joint evidence.
    expect(rule(s, 'evidence').status, ValidationRuleStatus.unknown);
    expect(rule(s, 'closures').status, ValidationRuleStatus.unknown);
  });
  test('no eligible output is legitimate; missing output with eligible options remains unknown', () {
    for (final options in [
      <RouteOption>[],
      [option('a', 100, 1000)],
    ]) {
      final trip = context(modes: {TransportMode.walking});
      final s = const MobilityValidationEvaluator().evaluate(
        project(trip, options, null),
      );
      expect(s.status, MobilityValidationStatus.noRecommendation);
      expect(s.evaluatedCount, 0);
      expect(
        rule(s, 'eligible').explanation,
        'No hubo alternativas elegibles para recomendación.',
      );
    }
    final s = const MobilityValidationEvaluator().evaluate(
      project(context(), [option('a', 1, 1)], null),
    );
    expect(rule(s, 'eligible').status, ValidationRuleStatus.unknown);
    expect(s.status, MobilityValidationStatus.noRecommendation);
  });
  test('rejects tampered recommendation/marker/reasons; not a tautological validator', () async {
    final options = [option('a', 100, 1000), option('b', 200, 2000)];
    final real = await VehicleRecommendationEngine(clock: () => instant)
        .recommend(context(), options);
    final marked = const MobilityValidationEvaluator().evaluate(
      project(context(), options, real, marked: 'b'),
    );
    expect(rule(marked, 'marked').status, ValidationRuleStatus.fail);
    final wrong = MobilityRecommendation(
      recommended: options[1],
      alternatives: [options[0]],
      reasons: [
        RecommendationReason(
          factor: RecommendationFactor.duration,
          explanation: 'test claim',
        ),
      ],
      evaluatedAt: instant,
    );
    final invalid = const MobilityValidationEvaluator().evaluate(
      project(context(), options, wrong),
    );
    expect(invalid.status, MobilityValidationStatus.inconsistent);
    expect(rule(invalid, 'duration').status, ValidationRuleStatus.fail);
    expect(rule(invalid, 'reason-0').status, ValidationRuleStatus.fail);
    final forged = MobilityRecommendation(
      recommended: option('a', 50, 500),
      alternatives: [],
      reasons: real.reasons,
      evaluatedAt: instant,
    );
    final forgedSnapshot = const MobilityValidationEvaluator().evaluate(
      project(context(), options, forged),
    );
    expect(rule(forgedSnapshot, 'metrics').status, ValidationRuleStatus.fail);
    expect(
      rule(forgedSnapshot, 'alternatives').status,
      ValidationRuleStatus.fail,
    );
  });
  test(
    'deterministic under DTO reorder preserving original providerOrder',
    () async {
      final options = [option('b', 100, 1000), option('a', 100, 1000)];
      final trip = context();
      final recommendation = await VehicleRecommendationEngine(
        clock: () => instant,
      ).recommend(trip, options);
      final input = project(trip, options, recommendation);
      final reordered = MobilityValidationInput(
        alternatives: input.alternatives.reversed,
        suggestedId: input.suggestedId,
        markedSuggestedId: input.markedSuggestedId,
        selectedId: input.selectedId,
        manuallySelected: false,
        reasons: input.reasons,
        recommendationIds: input.recommendationIds,
        suggestedSeconds: input.suggestedSeconds,
        suggestedMeters: input.suggestedMeters,
        evaluatedAt: input.evaluatedAt,
      );
      final a = const MobilityValidationEvaluator().evaluate(input);
      for (var i = 0; i < 3; i++) {
        final b = const MobilityValidationEvaluator().evaluate(reordered);
        expect(
          b.rules.map((r) => (r.id, r.status)),
          a.rules.map((r) => (r.id, r.status)),
        );
        expect(b.durationRank, a.durationRank);
      }
    },
  );
  test('zero denominator with positive numerator yields no percentage', () {
    final options = [option('a', 0, 0), option('b', 10, 10)];
    final wrong = MobilityRecommendation(
      recommended: options[1],
      alternatives: [options[0]],
      reasons: [
        RecommendationReason(
          factor: RecommendationFactor.duration,
          explanation: 'test',
        ),
      ],
      evaluatedAt: instant,
    );
    final s = const MobilityValidationEvaluator().evaluate(
      project(context(), options, wrong),
    );
    expect(s.extraDurationPercent, isNull);
    expect(s.extraDistancePercent, isNull);
  });
}
