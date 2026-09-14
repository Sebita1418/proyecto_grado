import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utilidad para convertir una polyline codificada de Google
/// en una lista de coordenadas utilizables por Google Maps.
class PolylineDecoder {
  const PolylineDecoder._();

  static List<LatLng> decode(String encodedPolyline) {
    if (encodedPolyline.trim().isEmpty) {
      return const <LatLng>[];
    }

    final points = <LatLng>[];

    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encodedPolyline.length) {
      final latitudeResult = _decodeValue(encodedPolyline, index);

      latitude += latitudeResult.value;
      index = latitudeResult.nextIndex;

      if (index >= encodedPolyline.length) {
        throw const FormatException(
          'La polyline contiene una coordenada incompleta.',
        );
      }

      final longitudeResult = _decodeValue(encodedPolyline, index);

      longitude += longitudeResult.value;
      index = longitudeResult.nextIndex;

      points.add(LatLng(latitude / 1e5, longitude / 1e5));
    }

    return points;
  }

  static _DecodedValue _decodeValue(String encodedPolyline, int startIndex) {
    var index = startIndex;
    var result = 0;
    var shift = 0;

    while (true) {
      if (index >= encodedPolyline.length) {
        throw const FormatException('La polyline tiene un formato inválido.');
      }

      final value = encodedPolyline.codeUnitAt(index) - 63;
      index++;

      if (value < 0 || value > 63) {
        throw const FormatException(
          'La polyline contiene caracteres inválidos.',
        );
      }

      result |= (value & 0x1f) << shift;
      shift += 5;

      if (value < 0x20) {
        break;
      }

      if (shift > 30) {
        throw const FormatException(
          'La polyline contiene una coordenada inválida.',
        );
      }
    }

    final decoded = (result & 1) != 0 ? ~(result >> 1) : result >> 1;

    return _DecodedValue(value: decoded, nextIndex: index);
  }
}

class _DecodedValue {
  const _DecodedValue({required this.value, required this.nextIndex});

  final int value;
  final int nextIndex;
}
