import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/controllers/route_planner_controller.dart';
import 'package:transporte_inteligente/models/google_route_result.dart';
import 'package:transporte_inteligente/services/google_routes_service.dart';

void main() {
  group('RoutePlannerController', () {
    test('starts in idle state', () {
      final controller = RoutePlannerController(
        computeRoute:
            ({
              required originLatitude,
              required originLongitude,
              required destinationLatitude,
              required destinationLongitude,
            }) async {
              return const GoogleRouteResult(
                distanceMeters: 1000,
                durationSeconds: 60,
                encodedPolyline: 'polyline',
              );
            },
      );

      expect(controller.status, RoutePlannerStatus.idle);
      expect(controller.isIdle, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.hasRoute, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.route, isNull);
      expect(controller.errorMessage, isNull);
    });

    test('forwards coordinates to route computation', () async {
      double? receivedOriginLatitude;
      double? receivedOriginLongitude;
      double? receivedDestinationLatitude;
      double? receivedDestinationLongitude;

      final controller = RoutePlannerController(
        computeRoute:
            ({
              required originLatitude,
              required originLongitude,
              required destinationLatitude,
              required destinationLongitude,
            }) async {
              receivedOriginLatitude = originLatitude;
              receivedOriginLongitude = originLongitude;
              receivedDestinationLatitude = destinationLatitude;
              receivedDestinationLongitude = destinationLongitude;

              return const GoogleRouteResult(
                distanceMeters: 8450,
                durationSeconds: 1260,
                encodedPolyline: 'encoded-polyline',
              );
            },
      );

      await controller.calculateRoute(
        originLatitude: 7.1254,
        originLongitude: -73.1198,
        destinationLatitude: 7.0731,
        destinationLongitude: -73.1052,
      );

      expect(receivedOriginLatitude, 7.1254);
      expect(receivedOriginLongitude, -73.1198);
      expect(receivedDestinationLatitude, 7.0731);
      expect(receivedDestinationLongitude, -73.1052);
    });

    test('stores route when calculation succeeds', () async {
      const expectedRoute = GoogleRouteResult(
        distanceMeters: 8450,
        durationSeconds: 1260,
        encodedPolyline: 'encoded-polyline',
      );

      final controller = RoutePlannerController(
        computeRoute:
            ({
              required originLatitude,
              required originLongitude,
              required destinationLatitude,
              required destinationLongitude,
            }) async {
              return expectedRoute;
            },
      );

      await controller.calculateRoute(
        originLatitude: 7.1254,
        originLongitude: -73.1198,
        destinationLatitude: 7.0731,
        destinationLongitude: -73.1052,
      );

      expect(controller.status, RoutePlannerStatus.success);
      expect(controller.isLoading, isFalse);
      expect(controller.hasRoute, isTrue);
      expect(controller.hasError, isFalse);
      expect(controller.route, same(expectedRoute));
      expect(controller.errorMessage, isNull);
    });

    test('exposes Google Routes error message', () async {
      final controller = RoutePlannerController(
        computeRoute:
            ({
              required originLatitude,
              required originLongitude,
              required destinationLatitude,
              required destinationLongitude,
            }) async {
              throw const GoogleRoutesException('API key not valid.');
            },
      );

      await controller.calculateRoute(
        originLatitude: 7.1254,
        originLongitude: -73.1198,
        destinationLatitude: 7.0731,
        destinationLongitude: -73.1052,
      );

      expect(controller.status, RoutePlannerStatus.error);
      expect(controller.isLoading, isFalse);
      expect(controller.hasRoute, isFalse);
      expect(controller.hasError, isTrue);
      expect(controller.route, isNull);
      expect(controller.errorMessage, 'API key not valid.');
    });

    test('uses generic message for unexpected errors', () async {
      final controller = RoutePlannerController(
        computeRoute:
            ({
              required originLatitude,
              required originLongitude,
              required destinationLatitude,
              required destinationLongitude,
            }) async {
              throw StateError('Unexpected failure');
            },
      );

      await controller.calculateRoute(
        originLatitude: 7.1254,
        originLongitude: -73.1198,
        destinationLatitude: 7.0731,
        destinationLongitude: -73.1052,
      );

      expect(controller.status, RoutePlannerStatus.error);
      expect(controller.hasError, isTrue);
      expect(
        controller.errorMessage,
        'Ocurrió un error inesperado al calcular la ruta.',
      );
    });

    test('notifies listeners when calculation starts and ends', () async {
      var notificationCount = 0;

      final controller = RoutePlannerController(
        computeRoute:
            ({
              required originLatitude,
              required originLongitude,
              required destinationLatitude,
              required destinationLongitude,
            }) async {
              return const GoogleRouteResult(
                distanceMeters: 1000,
                durationSeconds: 60,
                encodedPolyline: 'polyline',
              );
            },
      );

      controller.addListener(() {
        notificationCount++;
      });

      await controller.calculateRoute(
        originLatitude: 7.0,
        originLongitude: -73.0,
        destinationLatitude: 7.1,
        destinationLongitude: -73.1,
      );

      expect(notificationCount, 2);
    });

    test('remains loading while route computation is pending', () async {
      final completer = Completer<GoogleRouteResult>();

      final controller = RoutePlannerController(
        computeRoute:
            ({
              required originLatitude,
              required originLongitude,
              required destinationLatitude,
              required destinationLongitude,
            }) {
              return completer.future;
            },
      );

      final calculation = controller.calculateRoute(
        originLatitude: 7.1193,
        originLongitude: -73.1227,
        destinationLatitude: 7.1254,
        destinationLongitude: -73.1198,
      );

      expect(controller.status, RoutePlannerStatus.loading);
      expect(controller.isLoading, isTrue);
      expect(controller.hasRoute, isFalse);
      expect(controller.hasError, isFalse);

      completer.complete(
        const GoogleRouteResult(
          distanceMeters: 2500,
          durationSeconds: 600,
          encodedPolyline: 'encoded-polyline',
        ),
      );

      await calculation;

      expect(controller.status, RoutePlannerStatus.success);
      expect(controller.isLoading, isFalse);
      expect(controller.hasRoute, isTrue);
    });

    test('reset returns controller to idle state', () async {
      final controller = RoutePlannerController(
        computeRoute:
            ({
              required originLatitude,
              required originLongitude,
              required destinationLatitude,
              required destinationLongitude,
            }) async {
              return const GoogleRouteResult(
                distanceMeters: 1000,
                durationSeconds: 60,
                encodedPolyline: 'polyline',
              );
            },
      );

      await controller.calculateRoute(
        originLatitude: 7.0,
        originLongitude: -73.0,
        destinationLatitude: 7.1,
        destinationLongitude: -73.1,
      );

      expect(controller.hasRoute, isTrue);

      controller.reset();

      expect(controller.status, RoutePlannerStatus.idle);
      expect(controller.isIdle, isTrue);
      expect(controller.hasRoute, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.route, isNull);
      expect(controller.errorMessage, isNull);
    });
  });
}
