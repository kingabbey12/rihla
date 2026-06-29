import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Logs every route push/pop/replace so navigation transitions are traceable.
///
/// Used to confirm that confirming a route does NOT push a new (empty) page and
/// that the map page stays mounted. Logging is debug-only to avoid release noise.
class LoggingNavigatorObserver extends NavigatorObserver {
  void _log(String action, Route<dynamic>? route, Route<dynamic>? previous) {
    if (!kDebugMode) return;
    final current = route?.settings.name ?? route?.settings.arguments ?? route;
    final prev =
        previous?.settings.name ?? previous?.settings.arguments ?? previous;
    debugPrint('[nav] $action  current=$current  previous=$prev');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('push', route, previousRoute);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('pop', route, previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log('replace', newRoute, oldRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('remove', route, previousRoute);
    super.didRemove(route, previousRoute);
  }
}
