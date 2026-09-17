import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/mobility/mobility_conditions.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/mobility_recommendation.dart';
import 'package:transporte_inteligente/mobility/mobility_recommendation_engine.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/models/route_result.dart';

const origin = LatLng(7.1, -73.1);
const destination = LatLng(7.2, -73.2);

RouteResult route({
  List<LatLng>? points,
  double distance = 1000,
  double duration = 120,
}) => RouteResult(
  origin: origin,
  destination: destination,
  points: points ?? [origin, destination],
  distanceMeters: distance,
  durationSeconds: duration,
);

RouteOption option(String id, {RouteResult? result}) =>
    RouteOption.fromRouteResult(
      id: id,
      mode: TransportMode.driving,
      route: result ?? route(),
      source: 'osrm',
    );

class _StubEngine implements MobilityRecommendationEngine {
  _StubEngine(this.result);
  final MobilityRecommendation result;
  MobilityContext? receivedContext;
  List<RouteOption>? receivedOptions;

  @override
  Future<MobilityRecommendation> recommend(
    MobilityContext context,
    List<RouteOption> options,
  ) async {
    receivedContext = context;
    receivedOptions = options;
    return result;
  }
}

void main() {
  test('modos de transporte son independientes de perfiles de proveedor', () {
    expect(TransportMode.values, [
      TransportMode.driving,
      TransportMode.walking,
      TransportMode.cycling,
      TransportMode.publicTransport,
    ]);
  });

  test(
    'condiciones desconocidas no equivalen a congestión o reportes cero',
    () {
      final conditions = MobilityConditions();
      expect(conditions.isUnknown, isTrue);
      expect(conditions.congestion, isNull);
      expect(conditions.relevantIncidentCount, isNull);
      expect(conditions.estimatedDelaySeconds, isNull);
      expect(conditions.evaluatedAt, isNull);
    },
  );

  test('condiciones conocidas conservan evidencia y momento', () {
    final now = DateTime.utc(2026, 9, 16);
    final conditions = MobilityConditions(
      congestion: CongestionLevel.high,
      relevantIncidentCount: 2,
      estimatedDelaySeconds: 90,
      evaluatedAt: now,
    );
    expect(conditions.isUnknown, isFalse);
    expect(conditions.relevantIncidentCount, 2);
    expect(conditions.estimatedDelaySeconds, 90);
    expect(conditions.evaluatedAt, now);
    expect(
      () => MobilityConditions(relevantIncidentCount: -1),
      throwsArgumentError,
    );
    expect(
      () => MobilityConditions(estimatedDelaySeconds: double.nan),
      throwsArgumentError,
    );
  });

  test('adapta RouteResult sin duplicar mediciones y copia geometría', () {
    final points = <LatLng>[origin, destination];
    final original = route(points: points);
    final adapted = RouteOption.fromRouteResult(
      id: ' vehicular-1 ',
      mode: TransportMode.driving,
      route: original,
      source: 'osrm',
    );
    points.add(const LatLng(7.3, -73.3));
    expect(adapted.id, 'vehicular-1');
    expect(adapted.route.origin, origin);
    expect(adapted.route.destination, destination);
    expect(adapted.route.points, [origin, destination]);
    expect(adapted.route.distanceMeters, 1000);
    expect(adapted.route.durationSeconds, 120);
    expect(adapted.conditions.isUnknown, isTrue);
    expect(() => adapted.route.points.add(origin), throwsUnsupportedError);
  });

  test('RouteOption rechaza mediciones y geometría inválidas', () {
    expect(() => option('x', result: route(distance: -1)), throwsArgumentError);
    expect(
      () => option('x', result: route(distance: double.infinity)),
      throwsArgumentError,
    );
    expect(() => option('x', result: route(duration: -1)), throwsArgumentError);
    expect(
      () => option('x', result: route(duration: double.nan)),
      throwsArgumentError,
    );
    expect(
      () => option('x', result: route(points: [origin])),
      throwsArgumentError,
    );
    expect(
      () => option('x', result: route(points: [origin, const LatLng(91, 0)])),
      throwsArgumentError,
    );
    expect(() => option('  '), throwsArgumentError);
    expect(
      () => RouteOption.fromRouteResult(
        id: 'x',
        mode: TransportMode.driving,
        route: route(),
        source: ' ',
      ),
      throwsArgumentError,
    );
  });

  test(
    'MobilityContext conserva origen, modos y condiciones sin inventarlas',
    () {
      final modes = <TransportMode>{
        TransportMode.driving,
        TransportMode.walking,
      };
      final now = DateTime.utc(2026, 9, 16);
      final context = MobilityContext(
        origin: origin,
        destination: destination,
        allowedModes: modes,
        requestedAt: now,
      );
      modes.clear();
      expect(context.origin, origin);
      expect(context.destination, destination);
      expect(context.allowedModes, {
        TransportMode.driving,
        TransportMode.walking,
      });
      expect(context.requestedAt, now);
      expect(context.generalConditions.isUnknown, isTrue);
      expect(() => context.allowedModes.clear(), throwsUnsupportedError);
      expect(
        () => MobilityContext(
          origin: origin,
          destination: destination,
          allowedModes: {},
          requestedAt: now,
        ),
        throwsArgumentError,
      );
    },
  );

  test('recomendación conserva alternativas y razones estructuradas', () {
    final alternatives = <RouteOption>[option('b')];
    final reasons = <RecommendationReason>[
      RecommendationReason(
        factor: RecommendationFactor.duration,
        explanation: 'Duración observada en las alternativas disponibles',
      ),
    ];
    final now = DateTime.utc(2026, 9, 16);
    final recommendation = MobilityRecommendation(
      recommended: option('a'),
      alternatives: alternatives,
      reasons: reasons,
      evaluatedAt: now,
    );
    alternatives.clear();
    reasons.clear();
    expect(recommendation.alternatives.single.id, 'b');
    expect(recommendation.reasons.single.factor, RecommendationFactor.duration);
    expect(recommendation.evaluatedAt, now);
    expect(() => recommendation.alternatives.clear(), throwsUnsupportedError);
    expect(() => recommendation.reasons.clear(), throwsUnsupportedError);
    expect(
      () => MobilityRecommendation(
        recommended: option('a'),
        alternatives: [option('a')],
        reasons: [
          RecommendationReason(
            factor: RecommendationFactor.other,
            explanation: 'Dato',
          ),
        ],
        evaluatedAt: now,
      ),
      throwsArgumentError,
    );
    expect(
      () => RecommendationReason(
        factor: RecommendationFactor.other,
        explanation: ' ',
      ),
      throwsArgumentError,
    );
  });

  test(
    'contrato del motor recibe contexto y opciones sin imponer estrategia',
    () async {
      final now = DateTime.utc(2026, 9, 16);
      final context = MobilityContext(
        origin: origin,
        destination: destination,
        allowedModes: {TransportMode.driving},
        requestedAt: now,
      );
      final options = [option('a')];
      final result = MobilityRecommendation(
        recommended: options.single,
        alternatives: [],
        reasons: [
          RecommendationReason(
            factor: RecommendationFactor.other,
            explanation: 'Ejemplo de contrato',
          ),
        ],
        evaluatedAt: now,
      );
      final engine = _StubEngine(result);
      expect(await engine.recommend(context, options), same(result));
      expect(engine.receivedContext, same(context));
      expect(engine.receivedOptions, same(options));
    },
  );
}
