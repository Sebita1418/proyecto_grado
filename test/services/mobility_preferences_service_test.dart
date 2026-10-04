import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transporte_inteligente/mobility/transport_mode.dart';
import 'package:transporte_inteligente/services/mobility_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = MobilityPreferencesService();
  const key = MobilityPreferencesService.storageKey;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('traduce fallos de acceso para carga y guardado', () async {
    final failing = MobilityPreferencesService(
      preferencesLoader: () async {
        throw PlatformException(code: 'storage_unavailable');
      },
    );
    await expectLater(
      failing.load(),
      throwsA(isA<MobilityPreferencesStorageException>()),
    );
    await expectLater(
      failing.save({TransportMode.walking}),
      throwsA(isA<MobilityPreferencesStorageException>()),
    );
  });

  test('no oculta errores de programación', () async {
    final failing = MobilityPreferencesService(
      preferencesLoader: () async {
        throw StateError('programming error');
      },
    );
    await expectLater(failing.load(), throwsStateError);
    await expectLater(failing.save({TransportMode.walking}), throwsStateError);
  });

  test('un guardado rechazado no informa éxito', () async {
    final failing = MobilityPreferencesService(
      preferencesLoader: () async => RejectedPreferences(),
    );
    await expectLater(
      failing.save({TransportMode.walking}),
      throwsA(isA<MobilityPreferencesStorageException>()),
    );
  });

  test('almacenamiento vacío no supone preferencias', () async {
    expect(await service.load(), isEmpty);
  });

  test('guarda y recupera un modo con identificador estable', () async {
    await service.save({TransportMode.walking});
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList(key), ['walking']);
    expect(await const MobilityPreferencesService().load(), {
      TransportMode.walking,
    });
  });

  test('recupera múltiples modos y reemplaza la selección anterior', () async {
    await service.save(TransportMode.values.toSet());
    expect(await service.load(), TransportMode.values.toSet());
    await service.save({TransportMode.cycling, TransportMode.publicTransport});
    expect(await service.load(), {
      TransportMode.cycling,
      TransportMode.publicTransport,
    });
  });

  test('ignora obsoletos y duplicados conservando los conocidos', () async {
    SharedPreferences.setMockInitialValues({
      key: ['walking', 'flying', 'walking', 'En vehículo', 'publicTransport'],
    });
    expect(await service.load(), {
      TransportMode.walking,
      TransportMode.publicTransport,
    });
  });

  for (final value in <Object>[
    'obsolete',
    42,
    ['flying'],
    <String>[],
  ]) {
    test('dato obsoleto $value produce selección vacía', () async {
      SharedPreferences.setMockInitialValues({key: value});
      expect(await service.load(), isEmpty);
    });
  }
}

class RejectedPreferences implements SharedPreferences {
  @override
  Future<bool> setStringList(String key, List<String> value) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
