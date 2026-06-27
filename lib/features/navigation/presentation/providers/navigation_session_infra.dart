import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/data/repositories/navigation_session_repository_impl.dart';
import 'package:rihla/features/navigation/data/services/mock_navigation_session_engine.dart';
import 'package:rihla/features/navigation/data/services/polyline_maneuver_engine.dart';
import 'package:rihla/features/navigation/data/services/polyline_route_deviation_detector.dart';
import 'package:rihla/features/navigation/domain/repositories/navigation_session_repository.dart';
import 'package:rihla/features/navigation/domain/services/maneuver_engine.dart';
import 'package:rihla/features/navigation/domain/services/navigation_session_engine.dart';
import 'package:rihla/features/navigation/domain/services/route_deviation_detector.dart';
import 'package:rihla/features/navigation/presentation/services/navigation_tick_scheduler.dart';

final maneuverEngineProvider = Provider<ManeuverEngine>(
  (ref) => PolylineManeuverEngine(),
);

final routeDeviationDetectorProvider = Provider<RouteDeviationDetector>(
  (ref) => PolylineRouteDeviationDetector(),
);

final navigationSessionEngineProvider = Provider<NavigationSessionEngine>(
  (ref) => MockNavigationSessionEngine(
    maneuverEngine: ref.watch(maneuverEngineProvider),
    deviationDetector: ref.watch(routeDeviationDetectorProvider),
  ),
);

final navigationSessionRepositoryProvider = Provider<NavigationSessionRepository>(
  (ref) => NavigationSessionRepositoryImpl(),
);

final navigationTickSchedulerProvider = Provider<NavigationTickScheduler>(
  (ref) {
    final scheduler = NavigationTickScheduler();
    ref.onDispose(scheduler.dispose);
    return scheduler;
  },
);
