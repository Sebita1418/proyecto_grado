import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_suggestion.dart';

enum PlaceSuggestionFailure { timeout, connectivity, http, invalidResponse }

class PlaceSuggestionException implements Exception {
  const PlaceSuggestionException(
    this.message, {
    this.failure,
    this.statusCode,
    this.cause,
  });

  final String message;
  final PlaceSuggestionFailure? failure;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;
}

class PlaceSuggestionService {
  PlaceSuggestionService({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const double _bucaramangaLatitude = 7.119349;
  static const double _bucaramangaLongitude = -73.122742;

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  static Uri buildPhotonUri(String query) {
    final encodedQuery = Uri.encodeQueryComponent(query.trim());
    final encodedLatitude = Uri.encodeQueryComponent(
      _bucaramangaLatitude.toString(),
    );
    final encodedLongitude = Uri.encodeQueryComponent(
      _bucaramangaLongitude.toString(),
    );
    return Uri.parse(
      'https://photon.komoot.io/api/'
      '?q=$encodedQuery'
      '&lat=$encodedLatitude'
      '&lon=$encodedLongitude'
      '&limit=5',
    );
  }

  Future<List<PlaceSuggestion>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 3) return const [];
    final uri = buildPhotonUri(trimmedQuery);

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
    } on TimeoutException catch (error) {
      throw PlaceSuggestionException(
        'Photon tardó demasiado. Intenta de nuevo o calcula con la dirección escrita.',
        failure: PlaceSuggestionFailure.timeout,
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw PlaceSuggestionException(
        'No fue posible conectar con Photon: ${error.message}',
        failure: PlaceSuggestionFailure.connectivity,
        cause: error,
      );
    } catch (error) {
      throw PlaceSuggestionException(
        'No fue posible buscar lugares. Intenta de nuevo.',
        failure: PlaceSuggestionFailure.connectivity,
        cause: error,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlaceSuggestionException(
        'Photon respondió con HTTP ${response.statusCode}.',
        failure: PlaceSuggestionFailure.http,
        statusCode: response.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('La respuesta no es un objeto JSON.');
      }

      final features = decoded['features'];
      if (features is! List) {
        throw const FormatException('Falta la lista de features.');
      }

      final suggestions = <PlaceSuggestion>[];
      for (var index = 0; index < features.length; index++) {
        final place = _parseFeature(features[index]);
        if (place != null) suggestions.add(place);
        if (suggestions.length == 5) break;
      }
      return suggestions;
    } on FormatException catch (error) {
      throw PlaceSuggestionException(
        'Respuesta inválida de Photon: ${error.message}',
        failure: PlaceSuggestionFailure.invalidResponse,
        cause: error,
      );
    }
  }

  PlaceSuggestion? _parseFeature(dynamic feature) {
    if (feature is! Map<String, dynamic>) return null;

    final geometry = feature['geometry'];
    final properties = feature['properties'];
    if (geometry is! Map<String, dynamic> ||
        properties is! Map<String, dynamic>) {
      return null;
    }

    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;

    final longitude = _toValidCoordinate(coordinates[0], -180, 180);
    final latitude = _toValidCoordinate(coordinates[1], -90, 90);
    if (latitude == null || longitude == null) return null;

    final name =
        _text(properties['name']) ??
        _text(properties['street']) ??
        _text(properties['city']);
    if (name == null) return null;

    final descriptionParts = <String>[];
    final street = _text(properties['street']);
    final city = _text(properties['city']);
    final state = _text(properties['state']);
    final country = _text(properties['country']);

    if (street != null && street != name) {
      descriptionParts.add(
        [
          street,
          _text(properties['housenumber']),
        ].whereType<String>().join(' '),
      );
    }
    if (city != null && city != name) descriptionParts.add(city);
    if (state != null) descriptionParts.add(state);
    if (country != null) descriptionParts.add(country);

    return PlaceSuggestion(
      name: name,
      description: descriptionParts.toSet().join(', '),
      latitude: latitude,
      longitude: longitude,
    );
  }

  double? _toValidCoordinate(dynamic value, double minimum, double maximum) {
    final coordinate = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (coordinate == null ||
        !coordinate.isFinite ||
        coordinate < minimum ||
        coordinate > maximum) {
      return null;
    }
    return coordinate;
  }

  String? _text(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
