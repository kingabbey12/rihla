import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/map/domain/entities/map_camera.dart';
import 'package:rihla/features/map/domain/entities/map_style_variant.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';

void main() {
  group('MapCamera', () {
    test('copyWith overrides only provided fields', () {
      const camera = MapCamera(latitude: 10, longitude: 20, zoom: 5);
      final updated = camera.copyWith(zoom: 12, bearing: 90);

      expect(updated.latitude, 10);
      expect(updated.longitude, 20);
      expect(updated.zoom, 12);
      expect(updated.bearing, 90);
    });

    test('value equality', () {
      const a = MapCamera(latitude: 1, longitude: 2, zoom: 3);
      const b = MapCamera(latitude: 1, longitude: 2, zoom: 3);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('styleVariantForBrightness', () {
    test('maps brightness to variant', () {
      expect(
        styleVariantForBrightness(Brightness.light),
        MapStyleVariant.light,
      );
      expect(
        styleVariantForBrightness(Brightness.dark),
        MapStyleVariant.dark,
      );
    });
  });
}
