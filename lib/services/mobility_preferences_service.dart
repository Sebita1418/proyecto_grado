import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../mobility/transport_mode.dart';

class MobilityPreferencesStorageException implements Exception {
  const MobilityPreferencesStorageException();
}

/// Device-local preferences, independent of account and routing.
class MobilityPreferencesService {
  const MobilityPreferencesService({this.preferencesLoader});

  final Future<SharedPreferences> Function()? preferencesLoader;

  Future<SharedPreferences> _preferences() =>
      (preferencesLoader ?? SharedPreferences.getInstance)();

  static const storageKey = 'mobility_preferences.modes.v1';

  Future<Set<TransportMode>> load() async {
    try {
      return await _load().timeout(const Duration(seconds: 8));
    } on Exception {
      // Only storage exceptions are translated; programming Errors propagate.
      throw const MobilityPreferencesStorageException();
    }
  }

  Future<Set<TransportMode>> _load() async {
    final preferences = await _preferences();
    // A failed setter can update the plugin cache before storage succeeds.
    await preferences.reload();
    final value = preferences.get(storageKey);
    if (value is! List) return {};
    return {
      for (final mode in TransportMode.values)
        if (value.contains(mode.name)) mode,
    };
  }

  Future<void> save(Set<TransportMode> modes) async {
    final identifiers = [
      for (final mode in TransportMode.values)
        if (modes.contains(mode)) mode.name,
    ];
    try {
      final preferences = await _preferences();
      if (!await preferences.setStringList(storageKey, identifiers)) {
        throw const MobilityPreferencesStorageException();
      }
    } on Exception {
      throw const MobilityPreferencesStorageException();
    }
  }
}
