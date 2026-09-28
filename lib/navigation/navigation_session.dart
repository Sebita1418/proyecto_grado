import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_result.dart';
import '../services/location_service.dart';
import 'navigation_progress.dart';
import 'navigation_instruction.dart';

enum NavigationState {
  navigating,
  offRoutePending,
  rerouting,
  rerouteFailed,
  arrived,
}

typedef NavigationReroute = Future<RouteResult> Function({
  required LatLng origin,
  required LatLng destination,
});

class NavigationSession extends ChangeNotifier {
  NavigationSession(this.location, {this.reroute, DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final LocationService location;
  final NavigationReroute? reroute;
  final DateTime Function() _now;
  NavigationState state = NavigationState.navigating;
  LatLng? _originalDestination;
  DateTime? _lastRerouteAt, _lastFixAt;
  int _outsideFixes = 0, _rerouteEpoch = 0, _nextInstructionIndex = 0;
  bool _rerouting = false;
  List<double> _instructionOffsets = [];
  NavigationInstruction? get nextInstruction =>
      arrived ||
          route == null ||
          _nextInstructionIndex >= route!.instructions.length
      ? null
      : route!.instructions[_nextInstructionIndex];
  NavigationInstruction? get currentInstruction =>
      route == null || route!.instructions.isEmpty
      ? null
      : route!.instructions[(_nextInstructionIndex - 1).clamp(
          0,
          route!.instructions.length - 1,
        )];
  double? get distanceToInstruction => nextInstruction == null
      ? null
      : (_instructionOffsets[_nextInstructionIndex] -
                progress * _geometry!.total)
            .clamp(0.0, _geometry!.total);
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
    _originalDestination = selected.destination;
    _lastRerouteAt = null;
    _lastFixAt = null;
    _outsideFixes = 0;
    _rerouting = false;
    ++_rerouteEpoch;
    state = NavigationState.navigating;
    _prepareInstructions();
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
        if (result.recordedAt != null &&
            _lastFixAt != null &&
            !result.recordedAt!.isAfter(_lastFixAt!)) {
          return;
        }
        _lastFixAt = result.recordedAt ?? _lastFixAt;
        _acceptPosition(result.coordinates!);
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

  void _prepareInstructions() {
    _instructionOffsets = [];
    var previous = 0.0;
    for (final instruction in route!.instructions) {
      final projected = _geometry!.project(
        instruction.position,
        preferredProgress:
            instruction.distanceFromStart / route!.distanceMeters,
      );
      previous = (projected.progress * _geometry!.total).clamp(
        previous,
        _geometry!.total,
      );
      _instructionOffsets.add(previous);
    }
    _nextInstructionIndex =
        route!.instructions.length > 1 &&
            route!.instructions.first.type == ManeuverType.depart
        ? 1
        : 0;
  }

  void _acceptPosition(LatLng point) {
    if (!point.latitude.isFinite ||
        !point.longitude.isFinite ||
        point.latitude.abs() > 90 ||
        point.longitude.abs() > 180) {
      return;
    }
    currentPosition = point;
    final next = _geometry!.project(point, preferredProgress: progress);
    offRoute = next.distanceToRoute > 60;
    arrived =
        const Distance().as(LengthUnit.Meter, point, _originalDestination!) <=
        40;
    if (!offRoute) {
      projection = next;
      _outsideFixes = 0;
      _advanceInstructions();
      if (!_rerouting) {
        notice = null;
        state = NavigationState.navigating;
      }
    } else {
      _outsideFixes++;
      if (!_rerouting && state != NavigationState.rerouteFailed) {
        notice = 'Fuera de la ruta';
        state = NavigationState.offRoutePending;
      }
    }
    if (arrived) {
      state = NavigationState.arrived;
      notice = null;
    }
    notifyListeners();
    if (!arrived &&
        offRoute &&
        _outsideFixes >= 3 &&
        !_rerouting &&
        reroute != null &&
        (_lastRerouteAt == null ||
            _now().difference(_lastRerouteAt!) >=
                const Duration(seconds: 30))) {
      unawaited(_recalculate());
    }
  }

  void _advanceInstructions() {
    // Margen de 12 m tras la maniobra; el índice nunca retrocede por jitter.
    while (_nextInstructionIndex < _instructionOffsets.length &&
        progress * _geometry!.total >
            _instructionOffsets[_nextInstructionIndex] + 12) {
      _nextInstructionIndex++;
    }
  }

  Future<void> _recalculate() async {
    final epoch = ++_rerouteEpoch;
    final generation = _generation;
    final origin = currentPosition!;
    _rerouting = true;
    _lastRerouteAt = _now();
    state = NavigationState.rerouting;
    notice = 'Recalculando ruta…';
    notifyListeners();
    try {
      final updated = await reroute!(
        origin: origin,
        destination: _originalDestination!,
      ).timeout(const Duration(seconds: 20));
      if (!isActive || generation != _generation || epoch != _rerouteEpoch) {
        return;
      }
      // Si volvió a la ruta anterior o llegó, esta respuesta ya no es útil.
      if (!offRoute || arrived) return;
      if (updated.destination != _originalDestination ||
          updated.points.length < 2 ||
          !updated.distanceMeters.isFinite ||
          updated.distanceMeters <= 0 ||
          !updated.durationSeconds.isFinite ||
          updated.durationSeconds < 0 ||
          updated.points.any(
            (p) =>
                !p.latitude.isFinite ||
                !p.longitude.isFinite ||
                p.latitude.abs() > 90 ||
                p.longitude.abs() > 180,
          )) {
        throw const FormatException('Ruta recalculada inválida');
      }
      final geometry = NavigationProgress(updated.points);
      if (geometry.total <= 0) throw const FormatException('Geometría vacía');
      final latest = geometry.project(currentPosition!);
      if (latest.distanceToRoute > 60 &&
          const Distance().as(LengthUnit.Meter, origin, currentPosition!) >
              100) {
        state = NavigationState.offRoutePending;
        notice = 'La ubicación cambió. Esperando para recalcular.';
        return;
      }
      route = updated;
      _geometry = geometry;
      projection = latest.distanceToRoute <= 60 ? latest : null;
      _prepareInstructions();
      _advanceInstructions();
      _outsideFixes = 0;
      offRoute = latest.distanceToRoute > 60;
      state = NavigationState.navigating;
      notice = 'Ruta actualizada';
    } catch (_) {
      if (!isActive || generation != _generation || epoch != _rerouteEpoch) {
        return;
      }
      if (offRoute && !arrived) {
        state = NavigationState.rerouteFailed;
        notice = 'No fue posible recalcular la ruta.';
      }
    } finally {
      if (isActive && generation == _generation && epoch == _rerouteEpoch) {
        _rerouting = false;
        if (arrived) {
          state = NavigationState.arrived;
          notice = null;
        } else if (!offRoute && state == NavigationState.rerouting) {
          state = NavigationState.navigating;
          notice = null;
        }
        notifyListeners();
      }
    }
  }

  void _fail(String message) {
    ++_rerouteEpoch;
    _rerouting = false;
    notice = message;
    ++_generation;
    unawaited(_subscription?.cancel());
    _subscription = null;
    notifyListeners();
  }

  void pauseFollowing() {
    if (!following) return;
    following = false;
    notifyListeners();
  }

  void recenter() {
    following = true;
    notifyListeners();
  }

  void finish() {
    ++_rerouteEpoch;
    _rerouting = false;
    ++_generation;
    unawaited(_subscription?.cancel());
    _subscription = null;
    isActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    ++_rerouteEpoch;
    isActive = false;
    ++_generation;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
