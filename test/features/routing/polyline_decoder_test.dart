import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/routing/data/utils/polyline_decoder.dart';

void main() {
  group('PolylineDecoder', () {
    test('decodes empty string to empty list', () {
      expect(PolylineDecoder.decode(''), isEmpty);
    });

    test('decodes a known precision-5 polyline', () {
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final coords = PolylineDecoder.decode(encoded, precision: 5);
      expect(coords.length, greaterThan(1));
      expect(coords.first.latitude, closeTo(38.5, 0.01));
      expect(coords.first.longitude, closeTo(-120.2, 0.01));
    });

    test('round-trip coordinates are finite', () {
      const encoded = 'kfjiH`{isM';
      final coords = PolylineDecoder.decode(encoded, precision: 6);
      for (final c in coords) {
        expect(c.latitude.isFinite, isTrue);
        expect(c.longitude.isFinite, isTrue);
      }
    });
  });
}
