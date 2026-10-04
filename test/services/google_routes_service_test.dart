import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:transporte_inteligente/services/google_routes_service.dart';

void main() {
  group('GoogleRoutesService', () {
    test('sends the expected request and parses the route', () async {
      late http.Request capturedRequest;

      final client = MockClient((request) async {
        capturedRequest = request;

        return http.Response(
          jsonEncode({
            'routes': [
              {
                'distanceMeters': 8450,
                'duration': '1260s',
                'polyline': {'encodedPolyline': 'encoded-polyline'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = GoogleRoutesService(
        apiKey: 'test-api-key',
        client: client,
      );

      final result = await service.computeRoute(
        originLatitude: 7.1254,
        originLongitude: -73.1198,
        destinationLatitude: 7.0731,
        destinationLongitude: -73.1052,
      );

      expect(
        capturedRequest.url.toString(),
        'https://routes.googleapis.com/directions/v2:computeRoutes',
      );

      expect(capturedRequest.headers['X-Goog-Api-Key'], 'test-api-key');

      expect(
        capturedRequest.headers['X-Goog-FieldMask'],
        'routes.duration,routes.distanceMeters,'
        'routes.polyline.encodedPolyline',
      );

      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;

      expect(body['travelMode'], 'DRIVE');
      expect(body['routingPreference'], 'TRAFFIC_AWARE');
      expect(body['computeAlternativeRoutes'], isFalse);
      expect(body['languageCode'], 'es');
      expect(body['units'], 'METRIC');

      expect(body['origin']['location']['latLng']['latitude'], 7.1254);

      expect(body['origin']['location']['latLng']['longitude'], -73.1198);

      expect(body['destination']['location']['latLng']['latitude'], 7.0731);

      expect(body['destination']['location']['latLng']['longitude'], -73.1052);

      expect(result.distanceMeters, 8450);
      expect(result.durationSeconds, 1260);
      expect(result.encodedPolyline, 'encoded-polyline');
    });

    test('throws when API key is empty', () async {
      final client = MockClient((request) async {
        fail('HTTP request should not be executed.');
      });

      final service = GoogleRoutesService(apiKey: '', client: client);

      expect(
        () => service.computeRoute(
          originLatitude: 7.0,
          originLongitude: -73.0,
          destinationLatitude: 7.1,
          destinationLongitude: -73.1,
        ),
        throwsA(
          isA<GoogleRoutesException>().having(
            (error) => error.message,
            'message',
            'La API key de Google Routes no está configurada.',
          ),
        ),
      );
    });

    test('throws when origin latitude is invalid', () async {
      final client = MockClient((request) async {
        fail('HTTP request should not be executed.');
      });

      final service = GoogleRoutesService(apiKey: 'test-key', client: client);

      expect(
        () => service.computeRoute(
          originLatitude: 100,
          originLongitude: -73,
          destinationLatitude: 7,
          destinationLongitude: -73,
        ),
        throwsA(
          isA<GoogleRoutesException>().having(
            (error) => error.message,
            'message',
            'La latitud de origen debe estar entre -90 y 90.',
          ),
        ),
      );
    });

    test('throws when destination longitude is invalid', () async {
      final client = MockClient((request) async {
        fail('HTTP request should not be executed.');
      });

      final service = GoogleRoutesService(apiKey: 'test-key', client: client);

      expect(
        () => service.computeRoute(
          originLatitude: 7,
          originLongitude: -73,
          destinationLatitude: 7,
          destinationLongitude: 200,
        ),
        throwsA(
          isA<GoogleRoutesException>().having(
            (error) => error.message,
            'message',
            'La longitud de destino debe estar entre -180 y 180.',
          ),
        ),
      );
    });

    test('exposes Google error message on HTTP error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'API key not valid.'},
          }),
          400,
        );
      });

      final service = GoogleRoutesService(
        apiKey: 'invalid-key',
        client: client,
      );

      expect(
        () => service.computeRoute(
          originLatitude: 7.0,
          originLongitude: -73.0,
          destinationLatitude: 7.1,
          destinationLongitude: -73.1,
        ),
        throwsA(
          isA<GoogleRoutesException>().having(
            (error) => error.message,
            'message',
            'API key not valid.',
          ),
        ),
      );
    });

    test('throws when successful response is invalid', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'routes': []}), 200);
      });

      final service = GoogleRoutesService(apiKey: 'test-key', client: client);

      expect(
        () => service.computeRoute(
          originLatitude: 7.0,
          originLongitude: -73.0,
          destinationLatitude: 7.1,
          destinationLongitude: -73.1,
        ),
        throwsA(isA<GoogleRoutesException>()),
      );
    });

    test('uses a generic message for non JSON HTTP errors', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = GoogleRoutesService(apiKey: 'test-key', client: client);

      expect(
        () => service.computeRoute(
          originLatitude: 7.0,
          originLongitude: -73.0,
          destinationLatitude: 7.1,
          destinationLongitude: -73.1,
        ),
        throwsA(
          isA<GoogleRoutesException>().having(
            (error) => error.message,
            'message',
            'Google Routes respondió con HTTP 500.',
          ),
        ),
      );
    });
  });
}
