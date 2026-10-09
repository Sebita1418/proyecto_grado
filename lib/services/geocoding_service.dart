import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/address_precision.dart';

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
  LatLng? searchBias;
  final _cache = <String, List<GeocodingResult>>{};
  static Future<void> _queue = Future<void>.value();
  static DateTime? _lastRequest;

  Future<GeocodingResult?> search(String query) async {
    final candidates = await searchCandidates(query);
    return candidates.isEmpty ? null : candidates.first;
  }

  Future<List<GeocodingResult>> searchCandidates(String query) async {
    final normalized = AddressQuery(query).providerQuery;
    final bias = AddressQuery(query).hasCity ? null : searchBias;
    final cacheKey = '$normalized|${bias?.latitude}|${bias?.longitude}';
    if (normalized.isEmpty) return const [];
    if (cacheEnabled && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    // Tests with an injected HTTP client can bypass real-time scheduling.
    if (requestInterval == Duration.zero) {
      final result = await _search(normalized, bias);
      _remember(cacheKey, result);
      return result;
    }
    final previous = _queue;
    final done = Completer<void>();
    _queue = done.future;
    await previous;
    try {
      if (cacheEnabled && _cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }
      final last = _lastRequest;
      if (last != null) {
        final wait = requestInterval - DateTime.now().difference(last);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _lastRequest = DateTime.now();
      final result = await _search(normalized, bias);
      _remember(cacheKey, result);
      return result;
    } finally {
      done.complete();
    }
  }

  void _remember(String key, List<GeocodingResult> results) {
    if (!cacheEnabled) return;
    if (_cache.length >= 100) _cache.remove(_cache.keys.first);
    _cache[key] = List.unmodifiable(results);
  }

  /// Explicit user resolution only. Stop after evidence of a full match.
  Future<List<GeocodingResult>> resolve(
    String query, {
    bool Function()? isCurrent,
  }) async {
    final parsed = AddressQuery(AddressQuery(query).providerQuery);
    final bias = searchBias;
    final results = <GeocodingResult>[];
    for (final variant in parsed.variants.take(AddressQuery.maxVariants)) {
      if (isCurrent != null && !isCurrent()) break;
      List<GeocodingResult> matches;
      try {
        searchBias = bias;
        matches = await searchCandidates(variant);
      } catch (_) {
        if (results.isEmpty) rethrow;
        break;
      }
      if (isCurrent != null && !isCurrent()) break;
      for (final result in matches) {
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
      }
      if (results.any((r) => r.precision == AddressPrecision.specific)) break;
    }
    return parsed.rank(results, bias: bias ?? AddressQuery.metropolitanBias);
  }

  Future<List<GeocodingResult>> _search(String query, LatLng? bias) async {
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
    } on TimeoutException {
      throw TimeoutException(
        'Nominatim tardó demasiado. Reintenta o selecciona en el mapa.',
      );
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
      if (data.isEmpty) return const [];

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
        final city = AddressQuery.providerMunicipality(
          field('city') ??
              field('town') ??
              field('municipality') ??
              field('village'),
          field('county'),
        );
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
      return parsed.rank(candidates, bias: focus);
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
