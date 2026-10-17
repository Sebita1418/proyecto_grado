import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';

/// Reads the preserved Nominatim responses, including original URL/date/license.
/// These are geographic references, not invented coordinates or live GPS.
Future<Map<String, LatLng>> operationalReferencePoints() async {
  final records = jsonDecode(
    await File('test/fixtures/boundary-reference-points.json').readAsString(),
  ) as List;
  final points = <String, LatLng>{};
  for (final record in records) {
    final result = (record['results'] as List).single;
    points[record['query'].split(',').first as String] = LatLng(
      double.parse(result['lat']),
      double.parse(result['lon']),
    );
  }
  return points;
}
