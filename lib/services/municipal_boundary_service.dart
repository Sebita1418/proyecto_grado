import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../models/municipal_coverage.dart';
export '../models/municipal_coverage.dart';

/// A point is authorized by any verified allowed municipality. A missing
/// municipality makes unmatched points unknown, never outside.
class MunicipalBoundaryService {
  MunicipalBoundaryService({
    Future<String> Function()? loader,
    Iterable<MunicipalTerritory>? allowedMunicipalities,
    Future<String> Function(MunicipalTerritory)? municipalityLoader,
  }) : _legacyLoader = loader,
       municipalities = List.unmodifiable(
         allowedMunicipalities ?? operationalMunicipalities,
       ),
       _municipalityLoader = municipalityLoader ?? _readAsset;

  MunicipalBoundaryService.fromGeoJson(String source)
    : _legacyLoader = (() async => source),
      _anonymousGeometry = MunicipalGeometry.parse(source),
      municipalities = operationalMunicipalities,
      _municipalityLoader = _readAsset;

  static const assetPath = 'assets/geo/bucaramanga-mgn2024.geojson';
  static const operationalMunicipalities = [
    MunicipalTerritory(
      code: '68001',
      name: 'Bucaramanga',
      assetPath: assetPath,
    ),
    MunicipalTerritory(
      code: '68307',
      name: 'Girón',
      assetPath: 'assets/geo/giron-mgn2024.geojson',
    ),
    MunicipalTerritory(
      code: '68276',
      name: 'Floridablanca',
      assetPath: 'assets/geo/floridablanca-mgn2024.geojson',
    ),
  ];
  static MunicipalBoundaryService shared = MunicipalBoundaryService();
  static Future<String> _readAsset(MunicipalTerritory municipality) =>
      rootBundle.loadString(municipality.assetPath);

  final List<MunicipalTerritory> municipalities;
  final Future<String> Function()? _legacyLoader;
  final Future<String> Function(MunicipalTerritory) _municipalityLoader;
  final Map<String, MunicipalGeometry> _geometries = {};
  final Map<String, Object> _loadErrors = {};
  MunicipalGeometry? _anonymousGeometry;
  Object? _legacyError;
  bool _attempted = false;
  Future<void>? _loading;

  bool get available =>
      _anonymousGeometry != null ||
      (_legacyLoader == null &&
          municipalities.isNotEmpty &&
          municipalities.every((m) => _geometries.containsKey(m.code)));
  Map<String, Object> get loadErrors => Map.unmodifiable(_loadErrors);
  Object? get loadError =>
      _legacyError ?? (_loadErrors.isEmpty ? null : _loadErrors.values.first);
  String get coverageName => municipalities.map((m) => m.name).join(', ');
  List<List<List<LatLng>>> get polygons =>
      _anonymousGeometry?.polygons ??
      List.unmodifiable([
        for (final municipality in municipalities)
          ...?_geometries[municipality.code]?.polygons,
      ]);

  Future<void> load({bool retry = false}) {
    if (_loading != null) return _loading!;
    if (available || (_attempted && !retry)) return Future.value();
    final task = _load();
    _loading = task;
    return task.whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    _attempted = true;
    final loader = _legacyLoader;
    if (loader != null) {
      try {
        _anonymousGeometry = MunicipalGeometry.parse(await loader());
        _legacyError = null;
      } catch (error) {
        _anonymousGeometry = null;
        _legacyError = error;
      }
      return;
    }
    for (final municipality in municipalities) {
      if (_geometries.containsKey(municipality.code)) continue;
      try {
        final source = await _municipalityLoader(municipality);
        _geometries[municipality.code] = _verifiedGeometry(
          source,
          municipality,
        );
        _loadErrors.remove(municipality.code);
      } catch (error) {
        _loadErrors[municipality.code] = error;
      }
    }
  }

  static MunicipalGeometry _verifiedGeometry(
    String source,
    MunicipalTerritory municipality,
  ) {
    final data = jsonDecode(source);
    if (data is! Map ||
        data['type'] != 'FeatureCollection' ||
        data['features'] is! List ||
        (data['features'] as List).length != 1) {
      throw const FormatException('Recurso municipal no identificado.');
    }
    final feature = data['features'][0];
    final properties = feature is Map ? feature['properties'] : null;
    if (properties is! Map ||
        properties['mpio_cdpmp'] != municipality.code ||
        properties['mpio_cnmbr'] != municipality.name.toUpperCase() ||
        properties['mpio_tipo'] != 'MUNICIPIO' ||
        properties['mpio_nano'] != 2024) {
      throw const FormatException(
        'El recurso no corresponde al municipio MGN 2024 configurado.',
      );
    }
    return MunicipalGeometry.parse(source);
  }

  CoverageAssessment assess(LatLng point) =>
      assessCoordinates(point.latitude, point.longitude);
  CoverageAssessment assessCoordinates(double latitude, double longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      return CoverageAssessment(
        MunicipalCoverage.unknown,
        invalidCoordinates: true,
        coverageName: coverageName,
      );
    }
    final point = LatLng(latitude, longitude);
    final anonymous = _anonymousGeometry;
    if (anonymous != null) {
      return CoverageAssessment(
        anonymous.contains(point)
            ? MunicipalCoverage.inside
            : MunicipalCoverage.outside,
        coverageName: coverageName,
      );
    }
    final matches = [
      for (final municipality in municipalities)
        if (_geometries[municipality.code]?.contains(point) == true)
          municipality,
    ];
    if (matches.isNotEmpty) {
      return CoverageAssessment(
        MunicipalCoverage.inside,
        municipalities: List.unmodifiable(matches),
        coverageName: coverageName,
      );
    }
    return CoverageAssessment(
      available ? MunicipalCoverage.outside : MunicipalCoverage.unknown,
      coverageName: coverageName,
    );
  }

  String? endpointsMessage(LatLng origin, LatLng destination) {
    final first = assess(origin);
    if (!first.permitted) return first.message('El origen');
    final last = assess(destination);
    return last.permitted ? null : last.message('El destino');
  }
}

/// Ray casting on WGS84 lon/lat rings. All ring boundaries are included,
/// including the boundary of a hole. Ring winding does not affect membership.
/// Intended for local polygons that do not cross the antimeridian.
class MunicipalGeometry {
  MunicipalGeometry._(this.polygons);
  final List<List<List<LatLng>>> polygons;

  static MunicipalGeometry parse(String source) {
    final decoded = jsonDecode(source);
    final polygons = <List<List<LatLng>>>[];
    void geometry(dynamic value) {
      if (value is! Map) {
        throw const FormatException('Objeto GeoJSON inválido.');
      }
      if (value['crs'] != null) {
        final crs = value['crs'];
        final properties = crs is Map ? crs['properties'] : null;
        final name = properties is Map ? properties['name'] : null;
        if (name != 'urn:ogc:def:crs:OGC:1.3:CRS84' &&
            name != 'EPSG:4326' &&
            name != 'urn:ogc:def:crs:EPSG::4326') {
          throw const FormatException('Se requiere WGS84.');
        }
      }
      switch (value['type']) {
        case 'FeatureCollection':
          final features = value['features'];
          if (features is! List || features.isEmpty) {
            throw const FormatException('Sin features.');
          }
          for (final feature in features) {
            geometry(feature);
          }
        case 'Feature':
          geometry(value['geometry']);
        case 'Polygon':
          polygons.add(_polygon(value['coordinates']));
        case 'MultiPolygon':
          final values = value['coordinates'];
          if (values is! List || values.isEmpty) {
            throw const FormatException('MultiPolygon vacío.');
          }
          for (final polygon in values) {
            polygons.add(_polygon(polygon));
          }
        default:
          throw const FormatException('Se requiere Polygon o MultiPolygon.');
      }
    }

    geometry(decoded);
    return MunicipalGeometry._(List.unmodifiable(polygons));
  }

  static List<List<LatLng>> _polygon(dynamic values) {
    if (values is! List || values.isEmpty) {
      throw const FormatException('Polígono vacío.');
    }
    final rings = List<List<LatLng>>.unmodifiable(
      values.map((dynamic ring) {
        if (ring is! List || ring.length < 4) {
          throw const FormatException('Anillo incompleto.');
        }
        final points = <LatLng>[];
        for (final coordinate in ring) {
          if (coordinate is! List ||
              coordinate.length < 2 ||
              coordinate[0] is! num ||
              coordinate[1] is! num) {
            throw const FormatException('Coordenada inválida.');
          }
          final lon = (coordinate[0] as num).toDouble(),
              lat = (coordinate[1] as num).toDouble();
          if (!lon.isFinite ||
              !lat.isFinite ||
              lon.abs() > 180 ||
              lat.abs() > 90) {
            throw const FormatException('Coordenada fuera de WGS84.');
          }
          points.add(LatLng(lat, lon));
        }
        if (points.first != points.last || points.toSet().length < 3) {
          throw const FormatException('Anillo no cerrado o degenerado.');
        }
        var area = 0.0;
        final anchor = points.first;
        for (var i = 1; i < points.length; i++) {
          final a = points[i - 1], b = points[i];
          if ((a.longitude - b.longitude).abs() > 180) {
            throw const FormatException('Antimeridiano no soportado.');
          }
          area +=
              (a.longitude - anchor.longitude) *
                  (b.latitude - anchor.latitude) -
              (b.longitude - anchor.longitude) * (a.latitude - anchor.latitude);
        }
        if (area.abs() < 1e-18) throw const FormatException('Anillo sin área.');
        _validateRing(points);
        return List<LatLng>.unmodifiable(points);
      }),
    );
    for (final hole in rings.skip(1)) {
      if (hole.any((point) => _ring(point, rings.first) < 0)) {
        throw const FormatException('Hueco fuera del anillo exterior.');
      }
    }
    return rings;
  }

  static void _validateRing(List<LatLng> points) {
    // Reject self crossings. Bounding checks only accelerate intersection
    // detection; they never determine municipal membership.
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      for (var j = i + 2; j < points.length; j++) {
        if (i == 1 && j == points.length - 1) continue;
        final c = points[j - 1], d = points[j];
        final minX = a.longitude < b.longitude ? a.longitude : b.longitude;
        final maxX = a.longitude > b.longitude ? a.longitude : b.longitude;
        final minY = a.latitude < b.latitude ? a.latitude : b.latitude;
        final maxY = a.latitude > b.latitude ? a.latitude : b.latitude;
        if (maxX < (c.longitude < d.longitude ? c.longitude : d.longitude) ||
            minX > (c.longitude > d.longitude ? c.longitude : d.longitude) ||
            maxY < (c.latitude < d.latitude ? c.latitude : d.latitude) ||
            minY > (c.latitude > d.latitude ? c.latitude : d.latitude)) {
          continue;
        }
        double orientation(LatLng p, LatLng q, LatLng r) =>
            (q.longitude - p.longitude) * (r.latitude - p.latitude) -
            (q.latitude - p.latitude) * (r.longitude - p.longitude);
        final first = orientation(a, b, c), second = orientation(a, b, d);
        final third = orientation(c, d, a), fourth = orientation(c, d, b);
        if (first * second < 0 && third * fourth < 0) {
          throw const FormatException('Anillo con autointersección.');
        }
      }
    }
  }

  bool contains(LatLng point) {
    for (final polygon in polygons) {
      final outer = _ring(point, polygon.first);
      if (outer == 0) return true;
      if (outer < 0) continue;
      var inHole = false;
      for (final hole in polygon.skip(1)) {
        final status = _ring(point, hole);
        if (status == 0) return true;
        if (status > 0) inHole = true;
      }
      if (!inHole) return true;
    }
    return false;
  }

  // -1 outside, 0 boundary, 1 inside. Numerical tolerance is 1e-10 degrees,
  // not a geographic buffer, GPS accuracy radius or municipal approximation.
  static int _ring(LatLng point, List<LatLng> ring) {
    const tolerance = 1e-10;
    final x = point.longitude, y = point.latitude;
    var inside = false;
    for (var i = 1; i < ring.length; i++) {
      final a = ring[i - 1], b = ring[i];
      final dx = b.longitude - a.longitude, dy = b.latitude - a.latitude;
      final cross = (x - a.longitude) * dy - (y - a.latitude) * dx;
      final scale = dx.abs() + dy.abs();
      if (scale > 0 &&
          cross.abs() <= tolerance * scale &&
          x >=
              (a.longitude < b.longitude ? a.longitude : b.longitude) -
                  tolerance &&
          x <=
              (a.longitude > b.longitude ? a.longitude : b.longitude) +
                  tolerance &&
          y >=
              (a.latitude < b.latitude ? a.latitude : b.latitude) - tolerance &&
          y <=
              (a.latitude > b.latitude ? a.latitude : b.latitude) + tolerance) {
        return 0;
      }
      if ((a.latitude > y) != (b.latitude > y) &&
          x < dx * (y - a.latitude) / dy + a.longitude) {
        inside = !inside;
      }
    }
    return inside ? 1 : -1;
  }
}
