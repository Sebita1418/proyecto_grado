import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/utils/polyline_decoder.dart';

void main() {
  group('PolylineDecoder', () {
    test('decodifica una polyline válida', () {
      const encodedPolyline = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';

      final points = PolylineDecoder.decode(encodedPolyline);

      expect(points, hasLength(3));

      expect(points[0].latitude, closeTo(38.5, 0.00001));
      expect(points[0].longitude, closeTo(-120.2, 0.00001));

      expect(points[1].latitude, closeTo(40.7, 0.00001));
      expect(points[1].longitude, closeTo(-120.95, 0.00001));

      expect(points[2].latitude, closeTo(43.252, 0.00001));
      expect(points[2].longitude, closeTo(-126.453, 0.00001));
    });

    test('devuelve una lista vacía cuando la polyline está vacía', () {
      final points = PolylineDecoder.decode('');

      expect(points, isEmpty);
    });

    test('lanza FormatException cuando la polyline está incompleta', () {
      expect(
        () => PolylineDecoder.decode('_p~iF'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
