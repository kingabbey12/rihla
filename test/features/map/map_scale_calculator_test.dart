import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/map/domain/utils/map_scale_calculator.dart';

void main() {
  group('MapScaleCalculator', () {
    test('meters per pixel at equator, zoom 0 ≈ 156543', () {
      final mpp = MapScaleCalculator.metersPerPixel(0, 0);
      expect(mpp, closeTo(156543.03392, 0.01));
    });

    test('meters per pixel halves per zoom level', () {
      final z10 = MapScaleCalculator.metersPerPixel(0, 10);
      final z11 = MapScaleCalculator.metersPerPixel(0, 11);
      expect(z11, closeTo(z10 / 2, 0.0001));
    });

    test('higher latitude reduces ground resolution', () {
      final equator = MapScaleCalculator.metersPerPixel(0, 12);
      final high = MapScaleCalculator.metersPerPixel(60, 12);
      expect(high, lessThan(equator));
    });

    test('niceDistance rounds down to 1/2/3/5 magnitudes', () {
      expect(MapScaleCalculator.niceDistance(0), 0);
      expect(MapScaleCalculator.niceDistance(7), 5);
      expect(MapScaleCalculator.niceDistance(2.5), 2);
      expect(MapScaleCalculator.niceDistance(120), 100);
      expect(MapScaleCalculator.niceDistance(450), 300);
    });

    test('label formats meters and kilometers', () {
      expect(MapScaleCalculator.label(500), '500 m');
      expect(MapScaleCalculator.label(1000), '1 km');
      expect(MapScaleCalculator.label(1500), '1.5 km');
    });
  });
}
