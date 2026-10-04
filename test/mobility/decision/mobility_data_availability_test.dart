import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/mobility/decision/mobility_data_availability.dart';
import 'package:transporte_inteligente/mobility/mobility_conditions.dart';

void main() {
  test('evidencia completa conserva las seis categorías', () {
    final data = MobilityDataAvailability(
      statuses: {
        for (final kind in MobilityDataKind.values)
          kind: MobilityDataStatus.available,
      },
    );
    expect(data.hasAll(MobilityDataKind.values), isTrue);
  });

  test('evidencia parcial no satisface disponibilidad suficiente', () {
    final data = MobilityDataAvailability(
      statuses: {
        MobilityDataKind.location: MobilityDataStatus.available,
        MobilityDataKind.routing: MobilityDataStatus.partial,
      },
    );
    expect(data.hasAll({MobilityDataKind.location}), isTrue);
    expect(data.hasAll({MobilityDataKind.routing}), isFalse);
    expect(
      data.statusOf(MobilityDataKind.transport),
      MobilityDataStatus.unknown,
    );
  });

  test('sin datos de incidentes no equivale a cero incidentes', () {
    final data = MobilityDataAvailability(
      statuses: {
        MobilityDataKind.roadConditions: MobilityDataStatus.unavailable,
      },
    );
    final conditions = MobilityConditions();
    expect(data.hasAll({MobilityDataKind.roadConditions}), isFalse);
    expect(conditions.relevantIncidentCount, isNull);
    expect(conditions.isUnknown, isTrue);
  });

  test('datos disponibles no afirman condiciones favorables', () {
    final data = MobilityDataAvailability(
      statuses: {MobilityDataKind.roadConditions: MobilityDataStatus.available},
    );
    final conditions = MobilityConditions(relevantIncidentCount: 3);
    expect(data.hasAll({MobilityDataKind.roadConditions}), isTrue);
    expect(conditions.relevantIncidentCount, 3);
  });

  test('sin evidencia temporal no se infieren condiciones normales', () {
    final data = MobilityDataAvailability();
    expect(
      data.statusOf(MobilityDataKind.temporal),
      MobilityDataStatus.unknown,
    );
    expect(data.hasAll({MobilityDataKind.temporal}), isFalse);
  });

  test('snapshot de datos no cambia con el mapa de entrada', () {
    final input = {MobilityDataKind.routing: MobilityDataStatus.available};
    final data = MobilityDataAvailability(statuses: input);
    input.clear();
    expect(
      data.statusOf(MobilityDataKind.routing),
      MobilityDataStatus.available,
    );
    expect(() => data.statuses.clear(), throwsUnsupportedError);
  });
}
