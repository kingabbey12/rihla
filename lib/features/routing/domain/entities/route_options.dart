import 'package:rihla/features/routing/domain/entities/route_profile.dart';

/// Options that influence route calculation.
class RouteOptions {
  const RouteOptions({
    this.profiles = const [
      RouteProfile.fast,
      RouteProfile.safe,
      RouteProfile.eco,
      RouteProfile.scenic,
    ],
    this.alternateCount = 3,
    this.avoidHighways = false,
    this.avoidTolls = false,
    this.units = RouteUnits.kilometers,
  });

  final List<RouteProfile> profiles;
  final int alternateCount;
  final bool avoidHighways;
  final bool avoidTolls;
  final RouteUnits units;

  static const RouteOptions defaults = RouteOptions();
}

enum RouteUnits {
  kilometers,
  miles,
}
