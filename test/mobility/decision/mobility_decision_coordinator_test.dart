import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/mobility/decision/current_mobility_decision_adapter.dart';
import 'package:transporte_inteligente/mobility/decision/departure_time_context.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_data_availability.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_decision_coordinator.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_option_availability.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/route_option.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/mobility/vehicle_recommendation_engine.dart';

import '../mobility_domain_test.dart' show option;
import 'mobility_decision_context_test.dart' show trip, instant;

void main() {
  const adapter = CurrentMobilityDecisionAdapter();
  const coordinator = MobilityDecisionCoordinator();
  final now = DepartureTimeContext.now(instant);

  test(
    'driving preserves the real recommendation, reasons and alternatives',
    () async {
      final base = trip();
      final routes = [option('a'), option('b')];
      final recommendation = await VehicleRecommendationEngine().recommend(
        base,
        routes,
      );
      final context = adapter.build(trip: base, departure: now, routes: routes);
      final result = coordinator.decide(
        context,
        vehicleRecommendation: recommendation,
      );
      expect(result.recommendation, same(recommendation));
      expect(result.recommendation!.reasons, same(recommendation.reasons));
      expect(
        result.recommendation!.alternatives,
        same(recommendation.alternatives),
      );
      expect(result.evaluatedModes, [TransportMode.driving]);
      expect(result.nonEvaluableOptions, hasLength(3));
      expect(context.mobilityContext, same(base));
      expect(context.departureTime, same(now));
    },
  );

  test('no routes do not fabricate evidence or a recommendation', () {
    final context = adapter.build(trip: trip(), departure: now, routes: []);
    final result = coordinator.decide(context);
    expect(result.hasRecommendation, isFalse);
    expect(context.options.first.status, MobilityOptionStatus.insufficientData);
    expect(
      context.options.first.data.statusOf(MobilityDataKind.durationAndDistance),
      MobilityDataStatus.unavailable,
    );
  });

  test('available route without engine result is not treated as evaluated', () {
    final context = adapter.build(
      trip: trip(),
      departure: now,
      routes: [option('a')],
    );
    final result = coordinator.decide(context);
    expect(result.hasRecommendation, isFalse);
    expect(result.evaluatedModes, isEmpty);
    expect(result.unevaluatedOptions.single.mode, TransportMode.driving);
  });

  for (final mode in TransportMode.values.skip(1)) {
    test(
      '$mode does not reuse driving routes or invent travel times',
      () async {
        final base = trip(modes: {mode});
        final routes = [option('a')];
        final existing = await VehicleRecommendationEngine().recommend(
          trip(),
          routes,
        );
        final context = adapter.build(
          trip: base,
          departure: now,
          routes: routes,
        );
        final result = coordinator.decide(
          context,
          vehicleRecommendation: existing,
        );
        expect(result.hasRecommendation, isFalse);
        expect(result.nonEvaluableOptions.single.mode, mode);
        expect(
          result.nonEvaluableOptions.single.status,
          MobilityOptionStatus.unsupported,
        );
        expect(
          context.options.single.data.statusOf(MobilityDataKind.routing),
          MobilityDataStatus.unavailable,
        );
        expect(
          context.options.single.data.statusOf(
            MobilityDataKind.durationAndDistance,
          ),
          MobilityDataStatus.unavailable,
        );
      },
    );
  }

  test(
    'scheduled departure without temporal evidence has no recommendation',
    () async {
      final routes = [option('a')];
      final existing = await VehicleRecommendationEngine().recommend(
        trip(),
        routes,
      );
      final scheduled = DepartureTimeContext.scheduled(
        instant.add(const Duration(days: 1)),
      );
      final context = adapter.build(
        trip: trip(),
        departure: scheduled,
        routes: routes,
      );
      final result = coordinator.decide(
        context,
        vehicleRecommendation: existing,
      );
      expect(result.hasRecommendation, isFalse);
      expect(result.nonEvaluableOptions, hasLength(4));
      expect(
        context.options.first.status,
        MobilityOptionStatus.insufficientData,
      );
      expect(
        context.options.first.data.statusOf(MobilityDataKind.temporal),
        MobilityDataStatus.unavailable,
      );
      expect(context.departureTime.at, scheduled.at);
      expect(result.evaluatedModes, isEmpty);
    },
  );

  test('engine update failure leaves availability temporary', () {
    final context = adapter.build(
      trip: trip(),
      departure: now,
      routes: [option('a')],
      recommendationUnavailable: true,
    );
    expect(
      context.options.first.status,
      MobilityOptionStatus.temporarilyUnavailable,
    );
    expect(coordinator.decide(context).hasRecommendation, isFalse);
  });

  test('missing reports are not represented as clear road conditions', () {
    final context = adapter.build(
      trip: trip(),
      departure: now,
      routes: [option('a')],
    );
    expect(
      context.options.first.data.statusOf(MobilityDataKind.roadConditions),
      MobilityDataStatus.unavailable,
    );
    expect(context.options.first.canEvaluate, isTrue);
  });

  test('routes from another trip do not provide route evidence', () {
    final base = trip();
    final reverse = MobilityContext(
      origin: base.destination,
      destination: base.origin,
      allowedModes: base.allowedModes,
      requestedAt: instant,
    );
    final context = adapter.build(
      trip: reverse,
      departure: now,
      routes: [option('a')],
    );
    expect(context.options.first.canEvaluate, isFalse);
  });

  test('walking routes do not enable driving', () {
    final walk = RouteOption.fromRouteResult(
      id: 'walk',
      mode: TransportMode.walking,
      route: option('a').route,
    );
    final context = adapter.build(trip: trip(), departure: now, routes: [walk]);
    expect(context.options.first.canEvaluate, isFalse);
    expect(context.options.where((o) => o.canEvaluate), isEmpty);
  });
}
