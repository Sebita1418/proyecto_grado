import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

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
    this.timeout = requestTimeout,
    this.cacheEnabled = true,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const requestTimeout = Duration(seconds: 5);
  static const resolutionTimeout = Duration(seconds: 18);
  static final _currentRequestKey = Object();
  final http.Client _client;
  final bool _ownsClient;
  final Duration requestInterval, timeout;
  final bool cacheEnabled;
  LatLng? searchBias;
  final _cache = <String, GeocodingResult?>{};
  static Future<void> _queue = Future<void>.value();
  static DateTime? _lastRequest;

  Future<GeocodingResult?> search(String query) async {
    final isCurrent = Zone.current[_currentRequestKey] as bool Function()?;
    final normalized = AddressQuery.forProvider(query);
    final bias = AddressQuery(query).hasCity ? null : searchBias;
    final cacheKey =
        '${normalized.toLowerCase()}|${bias?.latitude}|${bias?.longitude}';
    if (normalized.isEmpty) return null;
    if (cacheEnabled && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }
    // Tests with an injected HTTP client can bypass real-time scheduling.
    if (requestInterval == Duration.zero) {
      final result = await _search(normalized, bias);
      if (cacheEnabled) {
        if (_cache.length >= 100) _cache.remove(_cache.keys.first);
        _cache[cacheKey] = result;
      }
      return result;
    }
    final previous = _queue;
    final done = Completer<void>();
    _queue = done.future;
    await previous;
    try {
      if (isCurrent != null && !isCurrent()) return null;
      if (cacheEnabled && _cache.containsKey(cacheKey)) {
        return _cache[cacheKey];
      }
      final last = _lastRequest;
      if (last != null) {
        final wait = requestInterval - DateTime.now().difference(last);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _lastRequest = DateTime.now();
      if (isCurrent != null && !isCurrent()) return null;
      final result = await _search(normalized, bias);
      if (_cache.length >= 100) _cache.remove(_cache.keys.first);
      if (cacheEnabled) _cache[cacheKey] = result;
      return result;
    } finally {
      done.complete();
    }
  }

  /// Explicit user resolution only. Stop after a useful compatible match.
  Future<List<GeocodingResult>> resolve(
    String query, {
    bool Function()? isCurrent,
  }) async {
    final parsed = AddressQuery(query);
    final bias = searchBias;
    final deadline = DateTime.now().add(resolutionTimeout);
    bool current() =>
        DateTime.now().isBefore(deadline) && (isCurrent?.call() ?? true);
    final results = <GeocodingResult>[];
    for (final variant in parsed.variants.toSet().take(
      AddressQuery.maxVariants,
    )) {
      if (!current()) break;
      GeocodingResult? result;
      try {
        searchBias = bias;
        result = await runZoned(
          () => search(variant),
          zoneValues: {_currentRequestKey: current},
        ).timeout(deadline.difference(DateTime.now()));
      } catch (_) {
        if (results.isEmpty) rethrow;
        break;
      }
      if (!current()) break;
      if (result == null) continue;
      if (parsed.primaryRoad != null &&
          (parsed.compatibility(result.road, result.houseNumber) == 0 ||
              !parsed.cityMatches(result.city))) {
        continue;
      }
      final quality = parsed.precisionFor(
        result.road,
        result.houseNumber,
        result.city,
      );
      final candidate = GeocodingResult(
        latitude: result.latitude,
        longitude: result.longitude,
        displayName: result.displayName,
        road: result.road,
        houseNumber: result.houseNumber,
        city: result.city,
        precision: quality,
      );
      if (!results.any(
        (r) =>
            r.latitude == candidate.latitude &&
            r.longitude == candidate.longitude &&
            r.displayName == candidate.displayName,
      )) {
        results.add(candidate);
      }
      // A compatible street is useful; the UI keeps its numbering unconfirmed.
      break;
    }
    return parsed.rank(results, bias: bias ?? AddressQuery.metropolitanBias);
  }

  Future<GeocodingResult?> _search(String query, LatLng? bias) async {
    final parsed = AddressQuery(query);
    final focus = bias ?? AddressQuery.metropolitanBias;
    final structured =
        parsed.hasCity &&
        parsed.houseNumber != null &&
        query.startsWith('${parsed.primaryRoad} ${parsed.houseNumber},');
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      if (!structured) 'q': query.trim(),
      if (structured) ...{
        'street': '${parsed.houseNumber} ${parsed.primaryRoad}',
        'city': parsed.locality.split(',').first.trim(),
        'country': 'Colombia',
        if (parsed.locality.split(',').length > 1 &&
            parsed.locality.split(',')[1].trim().toLowerCase() != 'colombia')
          'state': parsed.locality.split(',')[1].trim(),
      },
      'format': 'jsonv2',
      'limit': parsed.primaryRoad == null ? '1' : '5',
      'countrycodes': 'co',
      if (parsed.primaryRoad != null) 'addressdetails': '1',
      if (parsed.primaryRoad != null && !parsed.hasCity)
        'viewbox':
            '${(focus.longitude - .18).clamp(-180, 180)},${(focus.latitude + .18).clamp(-90, 90)},${(focus.longitude + .18).clamp(-180, 180)},${(focus.latitude - .18).clamp(-90, 90)}',
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

      final candidates = <GeocodingResult>[];
      for (final first in data) {
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

        final address = first['address'] is Map
            ? first['address'] as Map
            : const {};
        String? field(String key) =>
            address[key] is String ? address[key] as String : null;
        final road =
            field('road') ?? field('pedestrian') ?? field('residential');
        final house = field('house_number');
        final city =
            field('city') ??
            field('town') ??
            field('municipality') ??
            field('village');
        if (parsed.hasCity && city != null && !parsed.cityMatches(city)) {
          continue;
        }
        candidates.add(
          GeocodingResult(
            latitude: latitude,
            longitude: longitude,
            displayName: displayName,
            road: road,
            houseNumber: house,
            city: city,
            precision: parsed.precisionFor(road, house, city),
          ),
        );
      }
      return candidates.isEmpty
          ? null
          : parsed.rank(candidates, bias: focus).first;
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
