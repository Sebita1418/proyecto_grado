import 'package:flutter/foundation.dart';
import 'package:transporte_inteligente/models/google_route_result.dart';
import 'package:transporte_inteligente/services/google_routes_service.dart';

typedef ComputeRouteAction = Future<GoogleRouteResult> Function({
  required double originLatitude,
  required double originLongitude,
  required double destinationLatitude,
  required double destinationLongitude,
});

enum RoutePlannerStatus { idle, loading, success, error }

class RoutePlannerController extends ChangeNotifier {
  RoutePlannerController({required ComputeRouteAction computeRoute})
    : this._internal(computeRoute);

  RoutePlannerController._internal(this._computeRoute);

  factory RoutePlannerController.fromEnvironment() {
    final service = GoogleRoutesService.fromEnvironment();

    return RoutePlannerController(computeRoute: service.computeRoute);
  }

  final ComputeRouteAction _computeRoute;

  RoutePlannerStatus _status = RoutePlannerStatus.idle;
  GoogleRouteResult? _route;
  String? _errorMessage;

  RoutePlannerStatus get status => _status;

  GoogleRouteResult? get route => _route;

  String? get errorMessage => _errorMessage;

  bool get isIdle => _status == RoutePlannerStatus.idle;

  bool get isLoading => _status == RoutePlannerStatus.loading;

  bool get hasRoute => _status == RoutePlannerStatus.success && _route != null;

  bool get hasError =>
      _status == RoutePlannerStatus.error && _errorMessage != null;

  Future<void> calculateRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    _status = RoutePlannerStatus.loading;
    _route = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _computeRoute(
        originLatitude: originLatitude,
        originLongitude: originLongitude,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
      );

      _route = result;
      _errorMessage = null;
      _status = RoutePlannerStatus.success;
    } on GoogleRoutesException catch (error) {
      _route = null;
      _errorMessage = error.message;
      _status = RoutePlannerStatus.error;
    } catch (_) {
      _route = null;
      _errorMessage = 'Ocurrió un error inesperado al calcular la ruta.';
      _status = RoutePlannerStatus.error;
    }

    notifyListeners();
  }

  void reset() {
    _status = RoutePlannerStatus.idle;
    _route = null;
    _errorMessage = null;
    notifyListeners();
  }
}
