import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transporte_inteligente/mobility/mobility_conditions.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/mobility_recommendation.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';
import 'package:transporte_inteligente/models/route_result.dart';

const origin = LatLng(7.1, -73.1);
const destination = LatLng(7.2, -73.2);
final instant = DateTime.utc(2026, 9, 25, 12);

MobilityContext context([
  Set<TransportMode> modes = const {TransportMode.driving},
]) => MobilityContext(
  origin: origin,
  destination: destination,
  allowedModes: modes,
  requestedAt: instant.subtract(const Duration(seconds: 3)),
);

RouteResult route(double seconds, double meters) => RouteResult(
  origin: origin,
  destination: destination,
  points: const [origin, destination],
  durationSeconds: seconds,
  distanceMeters: meters,
);

RouteOption option(
  String id,
  double seconds,
  double meters, {
  TransportMode mode = TransportMode.driving,
  MobilityConditions? conditions,
}) => RouteOption.fromRouteResult(
  id: id,
  mode: mode,
  route: route(seconds, meters),
  conditions: conditions,
  source: 'osrm',
);

void main() {
  late VehicleRecommendationEngine engine;
  setUp(() => engine = VehicleRecommendationEngine(clock: () => instant));

  test(
    'menor duración gana aunque la distancia sea mayor; conserva alternativas',
    () async {
      final options = [
        option('a', 180, 1000),
        option('b', 120, 2000),
        option('c', 200, 500),
      ];
      final result = await engine.recommend(context(), options);
      expect(result.recommended, same(options[1]));
      expect(result.alternatives, [options[0], options[2]]);
      expect(options.map((o) => o.id), ['a', 'b', 'c']);
      expect(result.reasons.single.factor, RecommendationFactor.duration);
      expect(result.evaluatedAt, instant);
      expect(() => result.alternatives.clear(), throwsUnsupportedError);
    },
  );

  test('duración empatada usa distancia y explica el desempate', () async {
    final result = await engine.recommend(context(), [
      option('a', 120, 2000),
      option('b', 120, 1000),
    ]);
    expect(result.recommended.id, 'b');
    expect(result.reasons.map((r) => r.factor), [
      RecommendationFactor.duration,
      RecommendationFactor.distance,
    ]);
    expect(result.reasons.first.explanation, contains('Comparte'));
  });

  test(
    'empate completo conserva orden del proveedor y es reproducible',
    () async {
      final options = [option('b', 120, 1000), option('a', 120, 1000)];
      for (var i = 0; i < 3; i++) {
        final result = await engine.recommend(context(), options);
        expect(result.recommended.id, 'b');
        expect(
          result.reasons.last.explanation,
          contains('orden del proveedor'),
        );
        expect(
          result.reasons.any((r) => r.factor == RecommendationFactor.distance),
          isFalse,
        );
      }
    },
  );

  test('una candidata no afirma ganar una comparación', () async {
    final result = await engine.recommend(context(), [option('a', 120, 1000)]);
    expect(result.alternatives, isEmpty);
    expect(result.reasons.single.explanation, contains('Única alternativa'));
    expect(result.reasons.single.factor, RecommendationFactor.other);
  });

  test('vacío produce ausencia explícita de decisión', () async {
    await expectLater(
      engine.recommend(context(), []),
      throwsA(isA<NoEligibleVehicleRouteException>()),
    );
  });

  test(
    'driving incluido permite vehículo pero no simula otros modos',
    () async {
      final result = await engine.recommend(
        context({TransportMode.driving, TransportMode.walking}),
        [
          option('walk', 1, 1, mode: TransportMode.walking),
          option('car', 120, 1000),
        ],
      );
      expect(result.recommended.id, 'car');
      expect(result.alternatives, isEmpty);
      expect(result.reasons.single.explanation, contains('Única alternativa'));
    },
  );

  test('sin driving permitido no hay fallback silencioso', () async {
    await expectLater(
      engine.recommend(
        context({TransportMode.walking, TransportMode.cycling}),
        [option('car', 120, 1000)],
      ),
      throwsA(isA<NoEligibleVehicleRouteException>()),
    );
  });

  test(
    'sin candidatas driving no inventa una aunque el contexto lo permita',
    () async {
      await expectLater(
        engine.recommend(context(), [
          option('walk', 10, 100, mode: TransportMode.walking),
        ]),
        throwsA(isA<NoEligibleVehicleRouteException>()),
      );
    },
  );

  test('rechaza identidades duplicadas', () async {
    await expectLater(
      engine.recommend(context(), [
        option('a', 120, 1000),
        option('a', 60, 500),
      ]),
      throwsArgumentError,
    );
  });

  test('rechaza candidatas de otro origen o destino', () async {
    for (final endpoints in [
      (const LatLng(6, -73), destination),
      (origin, const LatLng(6, -73)),
    ]) {
      final otherTrip = RouteOption.fromRouteResult(
        id: 'other-trip',
        mode: TransportMode.driving,
        route: RouteResult(
          origin: endpoints.$1,
          destination: endpoints.$2,
          points: [endpoints.$1, endpoints.$2],
          durationSeconds: 1,
          distanceMeters: 1,
        ),
      );
      await expectLater(
        engine.recommend(context(), [option('valid', 120, 1000), otherTrip]),
        throwsArgumentError,
      );
    }
  });

  for (final invalid in [-1.0, double.nan, double.infinity]) {
    test('rechaza métricas inválidas $invalid en frontera del motor', () async {
      for (final metrics in [route(invalid, 1000), route(120, invalid)]) {
        await expectLater(
          engine.recommend(context(), [InvalidOption(metrics)]),
          throwsArgumentError,
        );
      }
    });
  }

  test(
    'condiciones desconocidas siguen desconocidas y no producen razones',
    () async {
      final unknown = option('a', 120, 1000);
      final known = option(
        'b',
        180,
        500,
        conditions: MobilityConditions(congestion: CongestionLevel.low),
      );
      final result = await engine.recommend(context(), [known, unknown]);
      expect(result.recommended, same(unknown));
      expect(unknown.conditions.isUnknown, isTrue);
      expect(unknown.conditions.estimatedDelaySeconds, isNull);
      expect(
        result.reasons.any((r) => r.factor == RecommendationFactor.conditions),
        isFalse,
      );
    },
  );

  test('compara sin redondear y acepta métricas cero', () async {
    final result = await engine.recommend(context(), [
      option('a', 0.1, 0),
      option('b', 0, 1),
    ]);
    expect(result.recommended.id, 'b');
  });
}

// Simulates a caller bypassing RouteOption's validating factory.
class InvalidOption implements RouteOption {
  InvalidOption(this.route);
  @override
  final RouteResult route;
  @override
  String get id => 'invalid';
  @override
  TransportMode get mode => TransportMode.driving;
  @override
  String? get source => null;
  @override
  MobilityConditions get conditions => MobilityConditions();
}
