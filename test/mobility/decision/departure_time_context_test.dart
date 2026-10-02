import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/mobility/decision/departure_time_context.dart';

void main() {
  test('now conserva el instante explícito sin consultar reloj', () {
    final at = DateTime.utc(2026, 10, 1, 12);
    final departure = DepartureTimeContext.now(at);
    expect(departure.isNow, isTrue);
    expect(departure.isScheduled, isFalse);
    expect(departure.at, at);
  });

  test('scheduled conserva fecha sin inferir condiciones futuras', () {
    final at = DateTime.utc(2026, 10, 2, 12);
    final departure = DepartureTimeContext.scheduled(at);
    expect(departure.isScheduled, isTrue);
    expect(departure.isNow, isFalse);
    expect(departure.at, at);
  });

  test('el tipo temporal no depende del reloj actual ni pierde zona', () {
    final at = DateTime(2020, 1, 1);
    final departure = DepartureTimeContext.scheduled(at);
    expect(departure.at.isUtc, isFalse);
    expect(departure.isScheduled, isTrue);
  });
}
