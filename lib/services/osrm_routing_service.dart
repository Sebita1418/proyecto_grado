import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/osrm_config.dart';
import '../models/route_result.dart';

class OsrmRoutingException implements Exception {
  const OsrmRoutingException(this.message);
  final String message;
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

  Future<RouteResult> route({
    required LatLng origin,
    required LatLng destination,
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
        'steps': 'false',
        'alternatives': 'false',
        'overview': 'full',
        'geometries': 'geojson',
      },
    );
    http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw const OsrmRoutingException(
        'El cálculo de ruta tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const OsrmRoutingException(
        'No fue posible conectar con el servicio de rutas.',
      );
    } catch (_) {
      throw const OsrmRoutingException(
        'No fue posible consultar el servicio de rutas.',
      );
    }
    if (response.statusCode != 200) {
      throw OsrmRoutingException(
        'El servicio de rutas respondió con HTTP ${response.statusCode}.',
      );
    }
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) throw const FormatException();
      if (body['code'] != 'Ok') {
        throw OsrmRoutingException(
          body['code'] == 'NoRoute'
              ? 'No se encontró una ruta vehicular entre los lugares.'
              : 'El servicio de rutas no pudo calcular el recorrido.',
        );
      }
      final routes = body['routes'];
      if (routes is! List ||
          routes.isEmpty ||
          routes.first is! Map<String, dynamic>) {
        throw const OsrmRoutingException('El servicio no devolvió una ruta.');
      }
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'];
      if (geometry is! Map<String, dynamic> ||
          geometry['type'] != 'LineString') {
        throw const OsrmRoutingException(
          'La geometría de la ruta es inválida.',
        );
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
        throw const OsrmRoutingException(
          'La distancia de la ruta es inválida.',
        );
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
      );
    } on FormatException {
      throw const OsrmRoutingException(
        'La respuesta del servicio de rutas no es válida.',
      );
    }
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
