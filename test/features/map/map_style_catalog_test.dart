import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/map/data/styles/map_style_catalog.dart';
import 'package:rihla/features/map/domain/entities/map_style_variant.dart';

void main() {
  group('MapStyleCatalog', () {
    test('light style is valid JSON with an OSM raster source', () {
      final style = MapStyleCatalog.styleFor(MapStyleVariant.light);
      final json = jsonDecode(style) as Map<String, dynamic>;

      expect(json['version'], 8);
      final sources = json['sources'] as Map<String, dynamic>;
      expect(sources.containsKey('osm'), isTrue);
      final osm = sources['osm'] as Map<String, dynamic>;
      expect(osm['type'], 'raster');
      expect(
        (osm['tiles'] as List).first,
        contains('tile.openstreetmap.org'),
      );
    });

    test('dark style is valid JSON with a dark background', () {
      final style = MapStyleCatalog.styleFor(MapStyleVariant.dark);
      final json = jsonDecode(style) as Map<String, dynamic>;

      final layers = json['layers'] as List;
      final background = layers.firstWhere(
        (l) => (l as Map)['id'] == 'background',
      ) as Map<String, dynamic>;
      final paint = background['paint'] as Map<String, dynamic>;
      expect(paint['background-color'], '#0F1419');
    });

    test('light and dark styles differ', () {
      expect(
        MapStyleCatalog.styleFor(MapStyleVariant.light),
        isNot(MapStyleCatalog.styleFor(MapStyleVariant.dark)),
      );
    });
  });
}
