import 'dart:async';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/route_result.dart';
import 'municipal_boundary_service.dart';

typedef TrafficQuery = Future<Map<String, dynamic>> Function(LatLng point);

/// A road-fragment observation, never an ETA for an entire OSRM route.
class RouteTrafficObservation {
  const RouteTrafficObservation({
    required this.queriedAt,
    required this.point,
    required this.currentSpeed,
    required this.freeFlowSpeed,
    required this.currentTravelTime,
    required this.freeFlowTravelTime,
    required this.confidence,
    required this.maximumOffsetMeters,
  });
  final DateTime queriedAt;
  final LatLng point;
  final double currentSpeed, freeFlowSpeed;
  final double currentTravelTime, freeFlowTravelTime, confidence;
  final double maximumOffsetMeters;
  static const provider = 'TomTom';
  static const endpoint =
      'https://api.tomtom.com/traffic/services/4/flowSegmentData/absolute/18/json';
}

class RouteTrafficSnapshot {
  const RouteTrafficSnapshot(this.status, {this.observation});
  final String status;
  final RouteTrafficObservation? observation;
  String get explanation => observation == null
      ? 'Tráfico actual no disponible ($status). OSRM no incluye tráfico en vivo; '
            'consulta el historial general al elegir una salida programada.'
      : 'TomTom: fragmento observado a ${observation!.currentSpeed} km/h, '
            'flujo libre ${observation!.freeFlowSpeed} km/h. '
            'Muestra parcial: no confirma carril ni sentido; no ajusta la duración '
            'OSRM ni determina una hora óptima.';
}

/// Disabled until the authenticated server proxy and its quota are provisioned.
/// One point per route, at most three routes, sequentially; no provider key here.
class RouteTrafficService {
  RouteTrafficService({
    this.enabled = const bool.fromEnvironment('TRAFFIC_PROXY_ENABLED'),
    TrafficQuery? query,
    MunicipalBoundaryService? boundary,
    DateTime Function()? clock,
  }) : _query = query ?? _invoke,
       _boundary = boundary ?? MunicipalBoundaryService.shared,
       _clock = clock ?? DateTime.now;

  final bool enabled;
  final TrafficQuery _query;
  final MunicipalBoundaryService _boundary;
  final DateTime Function() _clock;
  final _cache = <String, Map<String, dynamic>>{};
  static Future<Map<String, dynamic>> _invoke(LatLng point) async {
    final result = await Supabase.instance.client.functions.invoke(
      'traffic-flow',
      body: {'latitude': point.latitude, 'longitude': point.longitude},
    );
    if (result.status != 200) throw const FormatException('Proxy unavailable');
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<List<RouteTrafficSnapshot>> inspect(List<RouteResult> routes) async {
    if (!enabled) {
      return List.generate(
        routes.length,
        (_) => const RouteTrafficSnapshot('BLOCKED: sin proveedor configurado'),
      );
    }
    await _boundary.load();
    final result = <RouteTrafficSnapshot>[];
    for (var i = 0; i < routes.length; i++) {
      if (i >= 3) {
        result.add(const RouteTrafficSnapshot('límite de tres alternativas'));
        continue;
      }
      final route = routes[i];
      final point = route.points[route.points.length ~/ 2];
      if (!_boundary.assess(point).permitted) {
        result.add(const RouteTrafficSnapshot('fuera de cobertura verificada'));
        continue;
      }
      final key = '${point.latitude},${point.longitude}';
      try {
        final cached = _cache[key];
        final now = _clock().toUtc();
        final cachedAt = cached == null
            ? null
            : DateTime.tryParse(cached['queriedAt'] as String);
        if (cachedAt != null &&
            now.difference(cachedAt).inSeconds >= 0 &&
            now.difference(cachedAt).inSeconds < 60) {
          // Revalidate against this geometry; shared points can belong to different routes.
          result.add(validate(cached!, route, point, now));
          continue;
        }
        final response = await _query(point)
            .timeout(const Duration(seconds: 5));
        final snapshot = validate(response, route, point, _clock().toUtc());
        if (_cache.length >= 100) _cache.remove(_cache.keys.first);
        if (snapshot.observation != null) _cache[key] = response;
        result.add(snapshot);
      } on Object {
        result.add(const RouteTrafficSnapshot('error o timeout del proveedor'));
      }
    }
    return result;
  }

  static RouteTrafficSnapshot validate(
    Map<String, dynamic> response,
    RouteResult route,
    LatLng point,
    DateTime now,
  ) {
    try {
      final coordinate = response['queryCoordinate'] as Map;
      if (response['provider'] != RouteTrafficObservation.provider ||
          response['endpoint'] != RouteTrafficObservation.endpoint ||
          ((coordinate['latitude'] as num).toDouble() - point.latitude).abs() >
              1e-7 ||
          ((coordinate['longitude'] as num).toDouble() - point.longitude)
                  .abs() >
              1e-7) {
        return const RouteTrafficSnapshot(
          'procedencia o coordenada no coincidente',
        );
      }
      final queriedAt = DateTime.parse(response['queriedAt'] as String).toUtc();
      final age = now.toUtc().difference(queriedAt);
      final flow = Map<String, dynamic>.from(
        response['flowSegmentData'] as Map,
      );
      double number(String name) {
        final value = (flow[name] as num).toDouble();
        if (!value.isFinite || value < 0) throw const FormatException();
        return value;
      }

      final confidence = number('confidence');
      final current = number('currentSpeed'), free = number('freeFlowSpeed');
      final currentTime = number('currentTravelTime'),
          freeTime = number('freeFlowTravelTime');
      if (age.isNegative ||
          age > const Duration(seconds: 120) ||
          confidence < .8 ||
          confidence > 1 ||
          free <= 0 ||
          freeTime <= 0 ||
          flow['roadClosure'] != false) {
        return const RouteTrafficSnapshot(
          'muestra antigua, cierre o calidad insuficiente',
        );
      }
      final coordinates = (flow['coordinates'] as Map)['coordinate'] as List;
      final segment = coordinates
          .map(
            (c) => LatLng(
              (c['latitude'] as num).toDouble(),
              (c['longitude'] as num).toDouble(),
            ),
          )
          .toList();
      if (segment.length < 2 ||
          segment.any(
            (p) =>
                !p.latitude.isFinite ||
                !p.longitude.isFinite ||
                p.latitude.abs() > 90 ||
                p.longitude.abs() > 180,
          )) {
        throw const FormatException();
      }
      final offsets = segment.map((p) => distanceToLine(p, route.points));
      final maximum = offsets.reduce(math.max);
      if (maximum > 25 || distanceToLine(point, segment) > 25) {
        return const RouteTrafficSnapshot(
          'segmento sin correspondencia espacial fiable',
        );
      }
      return RouteTrafficSnapshot(
        'fragmento próximo; sentido no confirmado',
        observation: RouteTrafficObservation(
          queriedAt: queriedAt,
          point: point,
          currentSpeed: current,
          freeFlowSpeed: free,
          currentTravelTime: currentTime,
          freeFlowTravelTime: freeTime,
          confidence: confidence,
          maximumOffsetMeters: maximum,
        ),
      );
    } on Object {
      return const RouteTrafficSnapshot('respuesta inválida');
    }
  }

  static double distanceToLine(LatLng point, List<LatLng> line) {
    var minimum = double.infinity;
    const scale = 111195.08;
    for (var i = 1; i < line.length; i++) {
      final longitudeScale = scale * math.cos(point.latitude * math.pi / 180);
      final ax = (line[i - 1].longitude - point.longitude) * longitudeScale;
      final ay = (line[i - 1].latitude - point.latitude) * scale;
      final dx = (line[i].longitude - line[i - 1].longitude) * longitudeScale;
      final dy = (line[i].latitude - line[i - 1].latitude) * scale;
      final squared = dx * dx + dy * dy;
      final t = squared == 0
          ? 0.0
          : (-(ax * dx + ay * dy) / squared).clamp(0.0, 1.0);
      minimum = math.min(
        minimum,
        math.sqrt(math.pow(ax + t * dx, 2) + math.pow(ay + t * dy, 2)),
      );
    }
    return minimum;
  }
}
