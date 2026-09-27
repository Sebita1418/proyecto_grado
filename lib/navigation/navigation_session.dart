import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_result.dart';
import '../services/location_service.dart';
import 'navigation_progress.dart';

class NavigationSession extends ChangeNotifier {
  NavigationSession(this.location);
  final LocationService location;
  StreamSubscription<LocationResult>? _subscription;
  int _generation = 0;
  RouteResult? route;
  NavigationProgress? _geometry;
  RouteProjection? projection;
  LatLng? currentPosition;
  String destination = '';
  String? notice;
  bool isActive = false;
  bool arrived = false;
  bool offRoute = false;
  bool following = true;
  double get progress => projection?.progress ?? 0;
  double get remainingDistance => (route?.distanceMeters ?? 0) * (1 - progress);

  /// Proportional OSRM estimate; not live traffic or a dynamic ETA.
  double get remainingDuration =>
      (route?.durationSeconds ?? 0) * (1 - progress);

  bool start(RouteResult selected, String label) {
    if (isActive ||
        selected.points.length < 2 ||
        !selected.distanceMeters.isFinite ||
        selected.distanceMeters <= 0 ||
        !selected.durationSeconds.isFinite ||
        selected.durationSeconds < 0 ||
        ![selected.origin, selected.destination, ...selected.points].every(
          (p) =>
              p.latitude.isFinite &&
              p.longitude.isFinite &&
              p.latitude.abs() <= 90 &&
              p.longitude.abs() <= 180,
        )) {
      return false;
    }
    final geometry = NavigationProgress(selected.points);
    if (geometry.total <= 0) return false;
    route = selected;
    _geometry = geometry;
    destination = label;
    projection = null;
    currentPosition = null;
    arrived = false;
    offRoute = false;
    following = true;
    notice = 'Buscando ubicación GPS…';
    isActive = true;
    final generation = ++_generation;
    _subscription = location.watch().listen(
      (result) {
        if (!isActive || generation != _generation) return;
        if (result.status != LocationStatus.coordinatesObtained ||
            result.coordinates == null) {
          _fail(switch (result.status) {
            LocationStatus.serviceDisabled =>
              'GPS deshabilitado. Finaliza y activa la ubicación.',
            LocationStatus.permissionDenied ||
            LocationStatus.permissionDeniedForever =>
              'Permiso de ubicación denegado. Finaliza y revisa los permisos.',
            _ => 'Se perdió la ubicación GPS. Finaliza e intenta de nuevo.',
          });
          return;
        }
        final point = result.coordinates!;
        currentPosition = point;
        final next = _geometry!.project(point);
        offRoute = next.distanceToRoute > 60;
        // Do not advance along a distant road just because it projects near the end.
        if (!offRoute) projection = next;
        arrived =
            const Distance().as(
              LengthUnit.Meter,
              point,
              selected.destination,
            ) <=
            40;
        notice = null;
        notifyListeners();
      },
      onError: (Object error) {
        if (isActive && generation == _generation) {
          _fail('Se perdió la ubicación GPS. Finaliza e intenta de nuevo.');
        }
      },
      onDone: () {
        if (isActive && generation == _generation) {
          _fail('Seguimiento GPS detenido. Finaliza e intenta de nuevo.');
        }
      },
    );
    notifyListeners();
    return true;
  }

  void _fail(String message) {
    notice = message;
    ++_generation;
    unawaited(_subscription?.cancel());
    _subscription = null;
    notifyListeners();
  }

  void pauseFollowing() {
    following = false;
  }

  void recenter() {
    following = true;
    notifyListeners();
  }

  void finish() {
    ++_generation;
    unawaited(_subscription?.cancel());
    _subscription = null;
    isActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    ++_generation;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
