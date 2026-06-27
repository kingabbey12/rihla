import 'package:geolocator/geolocator.dart' as geo;
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';

/// Maps domain [LocationAccuracyLevel] to geolocator accuracy.
geo.LocationAccuracy toGeolocatorAccuracy(LocationAccuracyLevel level) {
  return switch (level) {
    LocationAccuracyLevel.lowest => geo.LocationAccuracy.lowest,
    LocationAccuracyLevel.low => geo.LocationAccuracy.low,
    LocationAccuracyLevel.medium => geo.LocationAccuracy.medium,
    LocationAccuracyLevel.high => geo.LocationAccuracy.high,
    LocationAccuracyLevel.best => geo.LocationAccuracy.best,
    LocationAccuracyLevel.bestForNavigation =>
      geo.LocationAccuracy.bestForNavigation,
  };
}
