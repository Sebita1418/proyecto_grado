import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_data_availability.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_option_availability.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';

MobilityDataAvailability routeEvidence() => MobilityDataAvailability(
  statuses: {
    MobilityDataKind.location: MobilityDataStatus.available,
    MobilityDataKind.routing: MobilityDataStatus.available,
    MobilityDataKind.durationAndDistance: MobilityDataStatus.available,
  },
);

MobilityOptionAvailability driving() => MobilityOptionAvailability(
  mode: TransportMode.driving,
  status: MobilityOptionStatus.evaluable,
  data: routeEvidence(),
);

void main() {
  test('driving evaluable está soportado y tiene evidencia suficiente', () {
    final option = driving();
    expect(option.canEvaluate, isTrue);
    expect(option.isSupported, isTrue);
    expect(option.hasSufficientData, isTrue);
  });

  test('soportado con datos insuficientes no se puede evaluar', () {
    final option = MobilityOptionAvailability(
      mode: TransportMode.driving,
      status: MobilityOptionStatus.insufficientData,
      data: MobilityDataAvailability(),
    );
    expect(option.isSupported, isTrue);
    expect(option.canEvaluate, isFalse);
    expect(option.hasSufficientData, isFalse);
  });

  test('indisponibilidad temporal no elimina soporte ni evidencia', () {
    final option = MobilityOptionAvailability(
      mode: TransportMode.driving,
      status: MobilityOptionStatus.temporarilyUnavailable,
      data: routeEvidence(),
    );
    expect(option.isSupported, isTrue);
    expect(option.hasSufficientData, isTrue);
    expect(option.canEvaluate, isFalse);
  });

  for (final mode in [
    TransportMode.walking,
    TransportMode.cycling,
    TransportMode.publicTransport,
  ]) {
    test('$mode existe sin fingir soporte ni datos productivos', () {
      final option = MobilityOptionAvailability(
        mode: mode,
        status: MobilityOptionStatus.unsupported,
        data: MobilityDataAvailability(),
      );
      expect(option.isSupported, isFalse);
      expect(option.canEvaluate, isFalse);
      expect(
        option.data.statusOf(MobilityDataKind.transport),
        MobilityDataStatus.unknown,
      );
    });
  }

  test('unsupported nunca es evaluable aunque tenga evidencia', () {
    final option = MobilityOptionAvailability(
      mode: TransportMode.walking,
      status: MobilityOptionStatus.unsupported,
      data: routeEvidence(),
    );
    expect(option.hasSufficientData, isTrue);
    expect(option.canEvaluate, isFalse);
  });

  test('rechaza evaluable con evidencia desconocida o parcial', () {
    for (final status in [
      MobilityDataStatus.unknown,
      MobilityDataStatus.partial,
      MobilityDataStatus.unavailable,
    ]) {
      expect(
        () => MobilityOptionAvailability(
          mode: TransportMode.driving,
          status: MobilityOptionStatus.evaluable,
          data: MobilityDataAvailability(
            statuses: {
              ...routeEvidence().statuses,
              MobilityDataKind.routing: status,
            },
          ),
        ),
        throwsArgumentError,
      );
    }
  });

  test('rechaza insuficiencia sin identificar evidencia faltante', () {
    expect(
      () => MobilityOptionAvailability(
        mode: TransportMode.driving,
        status: MobilityOptionStatus.insufficientData,
        data: routeEvidence(),
      ),
      throwsArgumentError,
    );
  });

  test('requisitos adicionales tipados conservan carencias del transporte', () {
    final requiredData = {
      MobilityDataKind.transport,
      MobilityDataKind.temporal,
    };
    final option = MobilityOptionAvailability(
      mode: TransportMode.publicTransport,
      status: MobilityOptionStatus.insufficientData,
      data: routeEvidence(),
      additionalRequiredData: requiredData,
    );
    requiredData.clear();
    expect(option.requiredData, contains(MobilityDataKind.transport));
    expect(option.canEvaluate, isFalse);
    expect(() => option.requiredData.clear(), throwsUnsupportedError);
  });
}
