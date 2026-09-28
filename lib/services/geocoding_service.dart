import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/geocoding_result.dart';
import 'address_query.dart';

class GeocodingException implements Exception {
  const GeocodingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeocodingService {
  GeocodingService({
    http.Client? client,
    this.requestInterval = const Duration(seconds: 1),
    this.timeout = const Duration(seconds: 8),
    this.cacheEnabled = true,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Duration requestInterval, timeout;
  final bool cacheEnabled;
  final _cache = <String, GeocodingResult?>{};
  static Future<void> _queue = Future<void>.value();
  static DateTime? _lastRequest;

  Future<GeocodingResult?> search(String query) async {
    final normalized = AddressQuery.forProvider(query);
    if (normalized.isEmpty) return null;
    if (cacheEnabled && _cache.containsKey(normalized)) {
      return _cache[normalized];
    }
    // Tests with an injected HTTP client can bypass real-time scheduling.
    if (requestInterval == Duration.zero) return _search(normalized);
    final previous = _queue;
    final done = Completer<void>();
    _queue = done.future;
    await previous;
    try {
      if (cacheEnabled && _cache.containsKey(normalized)) {
        return _cache[normalized];
      }
      final last = _lastRequest;
      if (last != null) {
        final wait = requestInterval - DateTime.now().difference(last);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _lastRequest = DateTime.now();
      final result = await _search(normalized);
      if (_cache.length >= 100) _cache.remove(_cache.keys.first);
      if (cacheEnabled) _cache[normalized] = result;
      return result;
    } finally {
      done.complete();
    }
  }

  Future<GeocodingResult?> _search(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query.trim(),
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'co',
    });

    http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'User-Agent':
                  'TransporteInteligente/1.0 (Flutter; Bucaramanga, CO)',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
    } on http.ClientException catch (error) {
      throw GeocodingException(
        'No fue posible conectar con Nominatim: ${error.message}',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeocodingException(
        'Nominatim respondió con HTTP ${response.statusCode}.',
      );
    }

    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! List) {
        throw const FormatException('Se esperaba una lista de resultados.');
      }
      if (data.isEmpty) return null;

      final first = data.first;
      if (first is! Map<String, dynamic>) {
        throw const FormatException('El primer resultado no es un objeto.');
      }

      final latitude = double.tryParse(first['lat']?.toString() ?? '');
      final longitude = double.tryParse(first['lon']?.toString() ?? '');
      if (latitude == null ||
          longitude == null ||
          !latitude.isFinite ||
          !longitude.isFinite ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        throw const FormatException('Las coordenadas son inválidas.');
      }

      final displayName = first['display_name'];
      if (displayName is! String || displayName.trim().isEmpty) {
        throw const FormatException('Falta el nombre de la ubicación.');
      }

      return GeocodingResult(
        latitude: latitude,
        longitude: longitude,
        displayName: displayName,
      );
    } on FormatException catch (error) {
      throw GeocodingException(
        'Respuesta inválida de Nominatim: ${error.message}',
      );
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
