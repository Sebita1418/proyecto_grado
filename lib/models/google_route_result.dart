class GoogleRouteResult {
  const GoogleRouteResult({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.encodedPolyline,
  });

  final int distanceMeters;
  final int durationSeconds;
  final String encodedPolyline;

  double get distanceKilometers => distanceMeters / 1000;

  Duration get duration => Duration(seconds: durationSeconds);

  factory GoogleRouteResult.fromJson(Map<String, dynamic> json) {
    final routes = json['routes'];

    if (routes is! List || routes.isEmpty) {
      throw const FormatException(
        'La respuesta de Google Routes no contiene rutas.',
      );
    }

    final firstRoute = routes.first;

    if (firstRoute is! Map<String, dynamic>) {
      throw const FormatException(
        'La ruta recibida tiene un formato inválido.',
      );
    }

    final distanceMeters = firstRoute['distanceMeters'];
    final duration = firstRoute['duration'];
    final polyline = firstRoute['polyline'];

    if (distanceMeters is! int) {
      throw const FormatException(
        'La respuesta no contiene una distancia válida.',
      );
    }

    if (duration is! String) {
      throw const FormatException(
        'La respuesta no contiene una duración válida.',
      );
    }

    if (polyline is! Map<String, dynamic>) {
      throw const FormatException(
        'La respuesta no contiene una polyline válida.',
      );
    }

    final encodedPolyline = polyline['encodedPolyline'];

    if (encodedPolyline is! String || encodedPolyline.isEmpty) {
      throw const FormatException(
        'La polyline recibida está vacía o es inválida.',
      );
    }

    final durationSeconds = _parseDurationSeconds(duration);

    return GoogleRouteResult(
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      encodedPolyline: encodedPolyline,
    );
  }

  static int _parseDurationSeconds(String value) {
    if (!value.endsWith('s')) {
      throw const FormatException(
        'La duración recibida tiene un formato inválido.',
      );
    }

    final numericPart = value.substring(0, value.length - 1);
    final seconds = double.tryParse(numericPart);

    if (seconds == null) {
      throw const FormatException(
        'La duración recibida no puede convertirse a segundos.',
      );
    }

    return seconds.round();
  }
}
