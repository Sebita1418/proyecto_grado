import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/osrm_config.dart';
import '../models/route_result.dart';
import '../navigation/navigation_instruction.dart';
import '../mobility/routing/routing_capabilities.dart';

class OsrmRoutingException implements Exception {
  const OsrmRoutingException(
    this.message, {
    this.failure = RoutingFailure.invalidResponse,
  });
  final String message;
  final RoutingFailure failure;
  @override
  String toString() => message;
}

class OsrmRoutingService {
  OsrmRoutingService({
    http.Client? client,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 15),
  }) : endpoint = endpoint ?? OsrmConfig.endpoint,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Uri endpoint;
  final Duration timeout;
  static final _publicClock = Stopwatch()..start();
  static Future<void> _publicQueue = Future.value();
  static int _nextPublicRequest = 0;

  Future<void> _respectPublicLimit() async {
    if (!{
      'router.project-osrm.org',
      'routing.openstreetmap.de',
    }.contains(endpoint.host)) {
      return;
    }
    final turn = _publicQueue.then((_) async {
      final delay = _nextPublicRequest - _publicClock.elapsedMilliseconds;
      if (delay > 0) await Future<void>.delayed(Duration(milliseconds: delay));
      _nextPublicRequest = _publicClock.elapsedMilliseconds + 1100;
    });
    _publicQueue = turn;
    await turn;
  }

  Future<RouteResult> route({
    required LatLng origin,
    required LatLng destination,
  }) async => (await _requestRoutes(
    origin: origin,
    destination: destination,
    alternatives: false,
  )).first;

  /// Requests every vehicle route returned by OSRM, in provider order.
  /// OSRM may return only one route even when alternatives are enabled.
  /// A malformed candidate rejects the entire response instead of silently
  /// presenting an incomplete set of candidates.
  Future<List<RouteResult>> routeAlternatives({
    required LatLng origin,
    required LatLng destination,
  }) => _requestRoutes(
    origin: origin,
    destination: destination,
    alternatives: true,
  );

  Future<List<RouteResult>> _requestRoutes({
    required LatLng origin,
    required LatLng destination,
    required bool alternatives,
  }) async {
    if (!_validPoint(origin) || !_validPoint(destination)) {
      throw const OsrmRoutingException(
        'Las coordenadas de origen o destino son inválidas.',
      );
    }
    final coordinates =
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
    final uri = endpoint.replace(
      path: '${endpoint.path}/route/v1/driving/$coordinates',
      queryParameters: {
        'steps': 'true',
        'alternatives': alternatives.toString(),
        'overview': 'full',
        'geometries': 'geojson',
      },
    );
    http.Response response;
    try {
      await _respectPublicLimit();
      response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'TransporteInteligente-academic-demo/1.0',
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const OsrmRoutingException(
        'El cálculo de ruta tardó demasiado. Intenta de nuevo.',
        failure: RoutingFailure.timeout,
      );
    } on http.ClientException {
      throw const OsrmRoutingException(
        'No fue posible conectar con el servicio de rutas.',
        failure: RoutingFailure.networkError,
      );
    } catch (_) {
      throw const OsrmRoutingException(
        'No fue posible consultar el servicio de rutas.',
        failure: RoutingFailure.networkError,
      );
    }
    if (response.statusCode != 200) {
      throw OsrmRoutingException(
        'El servicio de rutas respondió con HTTP ${response.statusCode}.',
        failure: RoutingFailure.unavailable,
      );
    }
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) throw const FormatException();
      if (body['code'] != 'Ok') {
        throw OsrmRoutingException(
          body['code'] == 'NoRoute'
              ? 'No se encontró una ruta entre los lugares.'
              : 'El servicio de rutas no pudo calcular el recorrido.',
          failure: body['code'] == 'NoRoute'
              ? RoutingFailure.noRoute
              : RoutingFailure.invalidResponse,
        );
      }
      final routes = body['routes'];
      if (routes is! List || routes.isEmpty) {
        throw const OsrmRoutingException('El servicio no devolvió una ruta.');
      }
      // Keep route() compatible: it has always consumed only routes.first.
      final candidates = alternatives ? routes : [routes.first];
      return List<RouteResult>.unmodifiable([
        for (final candidate in candidates)
          _parseRoute(candidate, origin: origin, destination: destination),
      ]);
    } on FormatException {
      throw const OsrmRoutingException(
        'La respuesta del servicio de rutas no es válida.',
      );
    }
  }

  RouteResult _parseRoute(
    Object? candidate, {
    required LatLng origin,
    required LatLng destination,
  }) {
    if (candidate is! Map<String, dynamic>) {
      throw const OsrmRoutingException('La alternativa de ruta es inválida.');
    }
    final route = candidate;
    final geometry = route['geometry'];
    if (geometry is! Map<String, dynamic> || geometry['type'] != 'LineString') {
      throw const OsrmRoutingException('La geometría de la ruta es inválida.');
    }
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) {
      throw const OsrmRoutingException('La geometría de la ruta está vacía.');
    }
    final points = <LatLng>[];
    for (final coordinate in coordinates) {
      if (coordinate is! List ||
          coordinate.length < 2 ||
          coordinate[0] is! num ||
          coordinate[1] is! num) {
        throw const OsrmRoutingException(
          'La geometría de la ruta es inválida.',
        );
      }
      // GeoJSON stores [longitude, latitude]; latlong2 expects LatLng(latitude, longitude).
      final point = LatLng(
        (coordinate[1] as num).toDouble(),
        (coordinate[0] as num).toDouble(),
      );
      if (!_validPoint(point)) {
        throw const OsrmRoutingException(
          'La geometría contiene coordenadas inválidas.',
        );
      }
      points.add(point);
    }
    final distance = route['distance'];
    final duration = route['duration'];
    if (distance is! num || !distance.isFinite || distance < 0) {
      throw const OsrmRoutingException('La distancia de la ruta es inválida.');
    }
    if (duration is! num || !duration.isFinite || duration < 0) {
      throw const OsrmRoutingException('La duración de la ruta es inválida.');
    }
    return RouteResult(
      origin: origin,
      destination: destination,
      points: List.unmodifiable(points),
      distanceMeters: distance.toDouble(),
      durationSeconds: duration.toDouble(),
      instructions: _parseInstructions(route['legs']),
    );
  }

  List<NavigationInstruction> _parseInstructions(Object? legs) {
    // Una respuesta sin steps conserva la ruta, sin fabricar instrucciones.
    if (legs is! List) return const [];
    final instructions = <NavigationInstruction>[];
    var offset = 0.0;
    for (final leg in legs) {
      if (leg is! Map || leg['steps'] is! List) return const [];
      for (final step in leg['steps'] as List) {
        if (step is! Map || step['maneuver'] is! Map) return const [];
        final maneuver = step['maneuver'] as Map;
        final location = maneuver['location'];
        final distance = step['distance'];
        final duration = step['duration'];
        if (location is! List ||
            location.length < 2 ||
            location[0] is! num ||
            location[1] is! num ||
            !(location[0] as num).isFinite ||
            !(location[1] as num).isFinite ||
            (location[0] as num).abs() > 180 ||
            (location[1] as num).abs() > 90 ||
            distance is! num ||
            !distance.isFinite ||
            distance < 0 ||
            duration is! num ||
            !duration.isFinite ||
            duration < 0) {
          return const [];
        }
        instructions.add(
          NavigationInstruction(
            type: switch (maneuver['type']) {
              'depart' => ManeuverType.depart,
              'arrive' => ManeuverType.arrive,
              'turn' || 'roundabout turn' => ManeuverType.turn,
              'continue' => ManeuverType.continueRoad,
              'merge' => ManeuverType.merge,
              'fork' => ManeuverType.fork,
              'roundabout' => ManeuverType.roundabout,
              'rotary' => ManeuverType.rotary,
              'new name' => ManeuverType.newName,
              'end of road' => ManeuverType.endOfRoad,
              'on ramp' => ManeuverType.onRamp,
              'off ramp' => ManeuverType.offRamp,
              'exit roundabout' || 'exit rotary' => ManeuverType.exitRoundabout,
              _ => ManeuverType.unknown,
            },
            direction: switch (maneuver['modifier']) {
              'left' => ManeuverDirection.left,
              'right' => ManeuverDirection.right,
              'slight left' => ManeuverDirection.slightLeft,
              'slight right' => ManeuverDirection.slightRight,
              'sharp left' => ManeuverDirection.sharpLeft,
              'sharp right' => ManeuverDirection.sharpRight,
              'straight' => ManeuverDirection.straight,
              'uturn' => ManeuverDirection.uturn,
              _ => ManeuverDirection.unknown,
            },
            position: LatLng(
              (location[1] as num).toDouble(),
              (location[0] as num).toDouble(),
            ),
            streetName: step['name'] is String ? step['name'] as String : '',
            distanceMeters: distance.toDouble(),
            durationSeconds: duration.toDouble(),
            distanceFromStart: offset,
            exit: maneuver['exit'] is int && (maneuver['exit'] as int) > 0
                ? maneuver['exit'] as int
                : null,
          ),
        );
        offset += distance;
      }
    }
    return List.unmodifiable(instructions);
  }

  bool _validPoint(LatLng point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude.abs() <= 90 &&
      point.longitude.abs() <= 180;

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
