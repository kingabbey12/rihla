import 'package:rihla/core/observability/analytics_event.dart';
import 'package:rihla/core/observability/log_sanitizer.dart';

/// Product analytics boundary.
///
/// Production wires this to Firebase Analytics and/or PostHog (see
/// `docs/PHASE18_PRODUCTION_HARDENING.md`). Properties are sanitized before
/// leaving the device.
abstract class AnalyticsService {
  void logEvent(AnalyticsEvent event, {Map<String, String> properties});
  void setScreen(String screenName);
  void identify({String? userId, bool isGuest});
  void reset();
}

/// Default analytics — discards everything (no network, no tracking).
class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  void logEvent(AnalyticsEvent event, {Map<String, String> properties = const {}}) {}

  @override
  void setScreen(String screenName) {}

  @override
  void identify({String? userId, bool isGuest = false}) {}

  @override
  void reset() {}
}

class RecordedAnalyticsEvent {
  const RecordedAnalyticsEvent(this.event, this.properties);

  final AnalyticsEvent event;
  final Map<String, String> properties;
}

/// In-memory analytics used by tests and debug builds.
class BufferingAnalyticsService implements AnalyticsService {
  BufferingAnalyticsService({LogSanitizer sanitizer = const LogSanitizer()})
      : _sanitizer = sanitizer;

  final LogSanitizer _sanitizer;

  final List<RecordedAnalyticsEvent> events = [];
  final List<String> screens = [];
  String? userId;
  bool isGuest = false;

  @override
  void logEvent(
    AnalyticsEvent event, {
    Map<String, String> properties = const {},
  }) {
    events.add(
      RecordedAnalyticsEvent(event, _sanitizer.scrubMap(properties)),
    );
  }

  @override
  void setScreen(String screenName) => screens.add(screenName);

  @override
  void identify({String? userId, bool isGuest = false}) {
    this.userId = userId;
    this.isGuest = isGuest;
  }

  @override
  void reset() {
    events.clear();
    screens.clear();
    userId = null;
    isGuest = false;
  }
}

/// Fans out analytics calls to multiple backends (e.g. Firebase + PostHog).
class CompositeAnalyticsService implements AnalyticsService {
  const CompositeAnalyticsService(this._delegates);

  final List<AnalyticsService> _delegates;

  @override
  void logEvent(
    AnalyticsEvent event, {
    Map<String, String> properties = const {},
  }) {
    for (final d in _delegates) {
      d.logEvent(event, properties: properties);
    }
  }

  @override
  void setScreen(String screenName) {
    for (final d in _delegates) {
      d.setScreen(screenName);
    }
  }

  @override
  void identify({String? userId, bool isGuest = false}) {
    for (final d in _delegates) {
      d.identify(userId: userId, isGuest: isGuest);
    }
  }

  @override
  void reset() {
    for (final d in _delegates) {
      d.reset();
    }
  }
}
