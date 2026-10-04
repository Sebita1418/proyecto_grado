import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_data_availability.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_decision_result.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_option_availability.dart';
import 'package:transporte_inteligente/mobility/mobility_recommendation.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/models/route_result.dart';

import '../mobility_domain_test.dart' show option;
import 'mobility_decision_context_test.dart'
    show decisionContext, unsupported, instant;
import 'mobility_option_availability_test.dart' show driving;

MobilityRecommendation recommendation() => MobilityRecommendation(
  recommended: option('a'),
  alternatives: [option('b')],
  reasons: [
    RecommendationReason(
      factor: RecommendationFactor.duration,
      explanation: 'Duración del proveedor',
    ),
  ],
  evaluatedAt: instant,
);

void main() {
  test('rechaza rutas de otro viaje tanto recomendadas como alternativas', () {
    final original = option('a');
    final otherTrip = RouteOption.fromRouteResult(
      id: 'other',
      mode: TransportMode.driving,
      route: RouteResult(
        origin: const LatLng(6, -73),
        destination: original.route.destination,
        points: [const LatLng(6, -73), original.route.destination],
        durationSeconds: 120,
        distanceMeters: 1000,
      ),
    );
    for (final routes in [
      [otherTrip, original],
      [original, otherTrip],
    ]) {
      expect(
        () => MobilityDecisionResult.recommended(
          context: decisionContext([driving()]),
          recommendation: MobilityRecommendation(
            recommended: routes.first,
            alternatives: [routes.last],
            reasons: recommendation().reasons,
            evaluatedAt: instant,
          ),
          evaluatedModes: [TransportMode.driving],
        ),
        throwsArgumentError,
      );
    }
  });

  test(
    'no oculta alternativas de un modo no evaluable en la recomendación',
    () {
      final walkingRoute = RouteOption.fromRouteResult(
        id: 'walking',
        mode: TransportMode.walking,
        route: option('a').route,
      );
      expect(
        () => MobilityDecisionResult.recommended(
          context: decisionContext([
            driving(),
            unsupported(TransportMode.walking),
          ]),
          recommendation: MobilityRecommendation(
            recommended: option('a'),
            alternatives: [walkingRoute],
            reasons: recommendation().reasons,
            evaluatedAt: instant,
          ),
          evaluatedModes: [TransportMode.driving],
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'reutiliza recomendación real del motor vehicular sin recalcular',
    () async {
      final context = decisionContext([
        driving(),
        unsupported(TransportMode.walking),
      ]);
      final existing = await VehicleRecommendationEngine().recommend(
        context.mobilityContext,
        [option('a')],
      );
      final result = MobilityDecisionResult.recommended(
        context: context,
        recommendation: existing,
        evaluatedModes: [TransportMode.driving],
      );
      expect(result.hasRecommendation, isTrue);
      expect(result.recommendation, same(existing));
      expect(result.noRecommendationReason, isNull);
      expect(result.evaluatedOptions.single.mode, TransportMode.driving);
      expect(result.nonEvaluableOptions.single.mode, TransportMode.walking);
    },
  );

  test('ausencia de evidencia es resultado válido sin excepción', () {
    final unavailable = MobilityOptionAvailability(
      mode: TransportMode.driving,
      status: MobilityOptionStatus.insufficientData,
      data: MobilityDataAvailability(),
    );
    final result = MobilityDecisionResult.withoutRecommendation(
      context: decisionContext([
        unavailable,
        unsupported(TransportMode.publicTransport),
      ]),
      reason: NoMobilityRecommendationReason.insufficientEvidence,
    );
    expect(result.hasRecommendation, isFalse);
    expect(result.recommendation, isNull);
    expect(
      result.noRecommendationReason,
      NoMobilityRecommendationReason.insufficientEvidence,
    );
    expect(result.nonEvaluableOptions, hasLength(2));
    expect(result.evaluatedOptions, isEmpty);
  });

  test('contexto vacío permite ausencia de opciones evaluables', () {
    final result = MobilityDecisionResult.withoutRecommendation(
      context: decisionContext([]),
      reason: NoMobilityRecommendationReason.noEvaluableOptions,
    );
    expect(result.hasRecommendation, isFalse);
  });

  test('no confunde capacidad con evaluación efectivamente realizada', () {
    final result = MobilityDecisionResult.withoutRecommendation(
      context: decisionContext([driving()]),
      reason: NoMobilityRecommendationReason.insufficientEvidence,
    );
    expect(result.evaluatedOptions, isEmpty);
    expect(result.nonEvaluableOptions, isEmpty);
    expect(result.unevaluatedOptions.single.mode, TransportMode.driving);
  });

  test('evaluación inconclusa conserva opciones evaluadas', () {
    final result = MobilityDecisionResult.withoutRecommendation(
      context: decisionContext([driving()]),
      reason: NoMobilityRecommendationReason.inconclusiveEvaluation,
      evaluatedModes: [TransportMode.driving],
    );
    expect(result.evaluatedOptions, hasLength(1));
    expect(result.hasRecommendation, isFalse);
  });

  for (final status in [
    MobilityOptionStatus.unsupported,
    MobilityOptionStatus.insufficientData,
    MobilityOptionStatus.temporarilyUnavailable,
  ]) {
    test('$status no admite recomendación ni evaluación', () {
      final context = decisionContext([
        MobilityOptionAvailability(
          mode: TransportMode.driving,
          status: status,
          data: MobilityDataAvailability(),
        ),
      ]);
      expect(
        () => MobilityDecisionResult.recommended(
          context: context,
          recommendation: recommendation(),
          evaluatedModes: [TransportMode.driving],
        ),
        throwsArgumentError,
      );
    });
  }

  test('rechaza evaluación duplicada o de modo no considerado', () {
    for (final modes in [
      [TransportMode.driving, TransportMode.driving],
      [TransportMode.walking],
    ]) {
      expect(
        () => MobilityDecisionResult.withoutRecommendation(
          context: decisionContext([driving()]),
          reason: NoMobilityRecommendationReason.insufficientEvidence,
          evaluatedModes: modes,
        ),
        throwsArgumentError,
      );
    }
  });

  test('rechaza recomendación de modo que no fue evaluado', () {
    expect(
      () => MobilityDecisionResult.recommended(
        context: decisionContext([driving()]),
        recommendation: recommendation(),
        evaluatedModes: [],
      ),
      throwsArgumentError,
    );
  });

  test('rechaza razones de ausencia contradictorias', () {
    for (final reason in [
      NoMobilityRecommendationReason.noEvaluableOptions,
      NoMobilityRecommendationReason.inconclusiveEvaluation,
    ]) {
      expect(
        () => MobilityDecisionResult.withoutRecommendation(
          context: decisionContext([driving()]),
          reason: reason,
        ),
        throwsArgumentError,
      );
    }
  });

  test('snapshot de evaluación y resultados derivados son inmutables', () {
    final modes = [TransportMode.driving];
    final result = MobilityDecisionResult.recommended(
      context: decisionContext([driving(), unsupported(TransportMode.walking)]),
      recommendation: recommendation(),
      evaluatedModes: modes,
    );
    modes.clear();
    expect(result.evaluatedModes, [TransportMode.driving]);
    expect(() => result.evaluatedModes.clear(), throwsUnsupportedError);
    expect(() => result.evaluatedOptions.clear(), throwsUnsupportedError);
    expect(() => result.nonEvaluableOptions.clear(), throwsUnsupportedError);
    expect(() => result.unevaluatedOptions.clear(), throwsUnsupportedError);
  });
}
