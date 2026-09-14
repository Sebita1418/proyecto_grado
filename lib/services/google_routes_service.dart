import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:transporte_inteligente/config/google_routes_config.dart';
import 'package:transporte_inteligente/models/google_route_result.dart';

class GoogleRoutesException implements Exception {
  const GoogleRoutesException(this.message);

  final String message;

  @override
  String toString() => 'GoogleRoutesException: $message';
}

class GoogleRoutesService {
  GoogleRoutesService({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  factory GoogleRoutesService.fromEnvironment({http.Client? client}) {
    return GoogleRoutesService(
      apiKey: GoogleRoutesConfig.apiKey,
      client: client,
    );
  }

  static final Uri _computeRoutesUri = Uri.parse(
    'https://routes.googleapis.com/directions/v2:computeRoutes',
  );

  final String apiKey;
  final http.Client _client;

  Future<GoogleRouteResult> computeRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const GoogleRoutesException(
        'La API key de Google Routes no está configurada.',
      );
    }

    _validateCoordinates(
      latitude: originLatitude,
      longitude: originLongitude,
      label: 'origen',
    );

    _validateCoordinates(
      latitude: destinationLatitude,
      longitude: destinationLongitude,
      label: 'destino',
    );

    try {
      final response = await _client.post(
        _computeRoutesUri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Goog-FieldMask':
              'routes.duration,routes.distanceMeters,'
              'routes.polyline.encodedPolyline',
        },
        body: jsonEncode({
          'origin': {
            'location': {
              'latLng': {
                'latitude': originLatitude,
                'longitude': originLongitude,
              },
            },
          },
          'destination': {
            'location': {
              'latLng': {
                'latitude': destinationLatitude,
                'longitude': destinationLongitude,
              },
            },
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
          'computeAlternativeRoutes': false,
          'languageCode': 'es',
          'units': 'METRIC',
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GoogleRoutesException(_extractErrorMessage(response));
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'La respuesta no es un objeto JSON válido.',
        );
      }

      return GoogleRouteResult.fromJson(decoded);
    } on GoogleRoutesException {
      rethrow;
    } on FormatException catch (error) {
      throw GoogleRoutesException(
        'Respuesta inválida de Google Routes: ${error.message}',
      );
    } on http.ClientException catch (error) {
      throw GoogleRoutesException(
        'No fue posible conectar con Google Routes: ${error.message}',
      );
    } catch (error) {
      throw GoogleRoutesException(
        'Ocurrió un error inesperado al consultar Google Routes: $error',
      );
    }
  }

  void _validateCoordinates({
    required double latitude,
    required double longitude,
    required String label,
  }) {
    if (latitude < -90 || latitude > 90) {
      throw GoogleRoutesException(
        'La latitud de $label debe estar entre -90 y 90.',
      );
    }

    if (longitude < -180 || longitude > 180) {
      throw GoogleRoutesException(
        'La longitud de $label debe estar entre -180 y 180.',
      );
    }
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];

        if (error is Map<String, dynamic>) {
          final message = error['message'];

          if (message is String && message.isNotEmpty) {
            return message;
          }
        }
      }
    } catch (_) {
      // Se utiliza el mensaje genérico de abajo.
    }

    return 'Google Routes respondió con HTTP ${response.statusCode}.';
  }
}
