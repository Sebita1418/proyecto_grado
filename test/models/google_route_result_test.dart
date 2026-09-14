import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/models/google_route_result.dart';

void main() {
  group('GoogleRouteResult', () {
    test('parses a valid Google Routes response', () {
      final result = GoogleRouteResult.fromJson({
        'routes': [
          {
            'distanceMeters': 8450,
            'duration': '1260s',
            'polyline': {'encodedPolyline': 'encoded-polyline'},
          },
        ],
      });

      expect(result.distanceMeters, 8450);
      expect(result.distanceKilometers, 8.45);
      expect(result.durationSeconds, 1260);
      expect(result.duration, const Duration(minutes: 21));
      expect(result.encodedPolyline, 'encoded-polyline');
    });

    test('supports decimal duration values', () {
      final result = GoogleRouteResult.fromJson({
        'routes': [
          {
            'distanceMeters': 1000,
            'duration': '90.5s',
            'polyline': {'encodedPolyline': 'polyline'},
          },
        ],
      });

      expect(result.durationSeconds, 91);
    });

    test('throws when routes list is empty', () {
      expect(
        () => GoogleRouteResult.fromJson({'routes': []}),
        throwsFormatException,
      );
    });

    test('throws when distance is missing', () {
      expect(
        () => GoogleRouteResult.fromJson({
          'routes': [
            {
              'duration': '60s',
              'polyline': {'encodedPolyline': 'polyline'},
            },
          ],
        }),
        throwsFormatException,
      );
    });

    test('throws when duration is invalid', () {
      expect(
        () => GoogleRouteResult.fromJson({
          'routes': [
            {
              'distanceMeters': 1000,
              'duration': 'invalid',
              'polyline': {'encodedPolyline': 'polyline'},
            },
          ],
        }),
        throwsFormatException,
      );
    });

    test('throws when polyline is missing', () {
      expect(
        () => GoogleRouteResult.fromJson({
          'routes': [
            {'distanceMeters': 1000, 'duration': '60s'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
