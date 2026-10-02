import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/mobility/decision/departure_time_context.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_data_availability.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_decision_context.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_option_availability.dart';
import 'package:transporte_inteligente/mobility/mobility_context.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';

import '../mobility_domain_test.dart' show origin, destination;
import 'mobility_option_availability_test.dart' show driving, routeEvidence;

final instant = DateTime.utc(2026, 10, 1, 12);

MobilityContext trip({Set<TransportMode>? modes}) => MobilityContext(
  origin: origin,
  destination: destination,
  requestedAt: instant,
  allowedModes: modes ?? TransportMode.values.toSet(),
);

MobilityOptionAvailability unsupported(TransportMode mode) =>
    MobilityOptionAvailability(
      mode: mode,
      status: MobilityOptionStatus.unsupported,
      data: MobilityDataAvailability(),
    );

MobilityDecisionContext decisionContext(
  List<MobilityOptionAvailability> options,
) => MobilityDecisionContext(
  mobilityContext: trip(),
  departureTime: DepartureTimeContext.now(instant),
  options: options,
);

void main() {
  test(
    'compone viaje, preferencias y varios modos sin duplicar coordenadas',
    () {
      final base = trip();
      final context = MobilityDecisionContext(
        mobilityContext: base,
        departureTime: DepartureTimeContext.now(instant),
        options: [driving(), unsupported(TransportMode.walking)],
      );
      expect(context.mobilityContext, same(base));
      expect(context.consideredModes, {
        TransportMode.driving,
        TransportMode.walking,
      });
      expect(
        context.dataAvailability[TransportMode.driving]!.hasAll({
          MobilityDataKind.routing,
        }),
        isTrue,
      );
      expect(
        context.dataAvailability[TransportMode.walking]!.hasAll({
          MobilityDataKind.routing,
        }),
        isFalse,
      );
    },
  );

  test('rechaza modos duplicados aunque tengan estados diferentes', () {
    expect(
      () => decisionContext([driving(), unsupported(TransportMode.driving)]),
      throwsArgumentError,
    );
  });

  test('rechaza modo ajeno a preferencias permitidas sin fallback', () {
    expect(
      () => MobilityDecisionContext(
        mobilityContext: trip(modes: {TransportMode.walking}),
        departureTime: DepartureTimeContext.now(instant),
        options: [driving()],
      ),
      throwsArgumentError,
    );
  });

  test('acepta contexto sin opciones sin fabricar medios', () {
    final context = decisionContext([]);
    expect(context.options, isEmpty);
    expect(context.consideredModes, isEmpty);
  });

  test('scheduled no permite evaluación con solo datos actuales de ruta', () {
    expect(
      () => MobilityDecisionContext(
        mobilityContext: trip(),
        departureTime: DepartureTimeContext.scheduled(
          instant.add(const Duration(days: 1)),
        ),
        options: [driving()],
      ),
      throwsArgumentError,
    );
  });

  test('scheduled representa insuficiencia temporal sin predicción', () {
    final context = MobilityDecisionContext(
      mobilityContext: trip(),
      departureTime: DepartureTimeContext.scheduled(instant),
      options: [
        MobilityOptionAvailability(
          mode: TransportMode.driving,
          status: MobilityOptionStatus.insufficientData,
          data: routeEvidence(),
          additionalRequiredData: {MobilityDataKind.temporal},
        ),
      ],
    );
    expect(context.options.single.canEvaluate, isFalse);
    expect(context.departureTime.isScheduled, isTrue);
  });

  test('permite futura evidencia temporal declarada sin producirla', () {
    final context = MobilityDecisionContext(
      mobilityContext: trip(),
      departureTime: DepartureTimeContext.scheduled(instant),
      options: [
        MobilityOptionAvailability(
          mode: TransportMode.driving,
          status: MobilityOptionStatus.evaluable,
          data: MobilityDataAvailability(
            statuses: {
              ...routeEvidence().statuses,
              MobilityDataKind.temporal: MobilityDataStatus.available,
            },
          ),
        ),
      ],
    );
    expect(context.options.single.canEvaluate, isTrue);
  });

  test('copia opciones y protege colecciones expuestas', () {
    final options = [driving()];
    final context = decisionContext(options);
    options.clear();
    expect(context.options, hasLength(1));
    expect(() => context.options.clear(), throwsUnsupportedError);
    expect(() => context.consideredModes.clear(), throwsUnsupportedError);
    expect(() => context.dataAvailability.clear(), throwsUnsupportedError);
  });
}
