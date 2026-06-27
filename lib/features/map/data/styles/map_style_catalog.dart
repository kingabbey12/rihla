import 'package:rihla/features/map/domain/entities/map_style_variant.dart';

/// Single source of truth for map style definitions.
///
/// Styles are OpenStreetMap-based MapLibre style documents. To change the
/// basemap, replace the style strings here — no widget code needs to change.
abstract final class MapStyleCatalog {
  /// OpenStreetMap raster tile endpoint.
  static const String _osmTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _attribution = '© OpenStreetMap contributors';

  /// Returns the MapLibre style JSON string for the given [variant].
  static String styleFor(MapStyleVariant variant) => switch (variant) {
        MapStyleVariant.light => _lightStyle,
        MapStyleVariant.dark => _darkStyle,
      };

  static String get _lightStyle => '''
{
  "version": 8,
  "name": "Rihla Light",
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": ["$_osmTiles"],
      "tileSize": 256,
      "attribution": "$_attribution",
      "maxzoom": 19
    }
  },
  "layers": [
    {
      "id": "background",
      "type": "background",
      "paint": { "background-color": "#F8FAFA" }
    },
    {
      "id": "osm",
      "type": "raster",
      "source": "osm",
      "paint": { "raster-opacity": 1 }
    }
  ]
}
''';

  /// Dark variant darkens the raster basemap over a dark background.
  /// Swap in an OSM vector dark style here for richer theming later.
  static String get _darkStyle => '''
{
  "version": 8,
  "name": "Rihla Dark",
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": ["$_osmTiles"],
      "tileSize": 256,
      "attribution": "$_attribution",
      "maxzoom": 19
    }
  },
  "layers": [
    {
      "id": "background",
      "type": "background",
      "paint": { "background-color": "#0F1419" }
    },
    {
      "id": "osm",
      "type": "raster",
      "source": "osm",
      "paint": {
        "raster-opacity": 0.85,
        "raster-brightness-min": 0,
        "raster-brightness-max": 0.55,
        "raster-contrast": -0.1,
        "raster-saturation": -0.35
      }
    }
  ]
}
''';
}
