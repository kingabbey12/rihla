import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/log_sanitizer.dart';

/// Crash and non-fatal error reporting boundary.
///
/// Production wires this to Firebase Crashlytics (see
/// `docs/PHASE18_PRODUCTION_HARDENING.md`). Default builds use [NoOpCrashReporter];
/// tests use [BufferingCrashReporter]. All inputs are sanitized via
/// [LogSanitizer] before reaching any backend.
abstract class CrashReporter {
  void recordFatal(Object error, StackTrace? stack, {String? reason});
  void recordNonFatal(Object error, StackTrace? stack, {String? reason});
  void addBreadcrumb(Breadcrumb crumb);
  void setUserContext({String? userId, bool isGuest});
  void setCustomKey(String key, String value);
}

/// Default reporter — discards everything (privacy-safe, no network).
class NoOpCrashReporter implements CrashReporter {
  const NoOpCrashReporter();

  @override
  void recordFatal(Object error, StackTrace? stack, {String? reason}) {}

  @override
  void recordNonFatal(Object error, StackTrace? stack, {String? reason}) {}

  @override
  void addBreadcrumb(Breadcrumb crumb) {}

  @override
  void setUserContext({String? userId, bool isGuest = false}) {}

  @override
  void setCustomKey(String key, String value) {}
}

/// In-memory reporter used by tests and as a base for backend adapters.
class BufferingCrashReporter implements CrashReporter {
  BufferingCrashReporter({
    LogSanitizer sanitizer = const LogSanitizer(),
    this.maxBreadcrumbs = 50,
  }) : _sanitizer = sanitizer;

  final LogSanitizer _sanitizer;
  final int maxBreadcrumbs;

  final List<Breadcrumb> breadcrumbs = [];
  final List<RecordedError> errors = [];
  final Map<String, String> customKeys = {};
  String? userId;
  bool isGuest = false;

  @override
  void recordFatal(Object error, StackTrace? stack, {String? reason}) {
    errors.add(
      RecordedError(
        message: _sanitizer.scrub(error.toString()),
        reason: reason == null ? null : _sanitizer.scrub(reason),
        fatal: true,
        stack: stack,
      ),
    );
  }

  @override
  void recordNonFatal(Object error, StackTrace? stack, {String? reason}) {
    errors.add(
      RecordedError(
        message: _sanitizer.scrub(error.toString()),
        reason: reason == null ? null : _sanitizer.scrub(reason),
        fatal: false,
        stack: stack,
      ),
    );
  }

  @override
  void addBreadcrumb(Breadcrumb crumb) {
    breadcrumbs.add(
      Breadcrumb(
        message: _sanitizer.scrub(crumb.message),
        category: crumb.category,
        level: crumb.level,
        data: _sanitizer.scrubMap(crumb.data),
        timestamp: crumb.timestamp,
      ),
    );
    if (breadcrumbs.length > maxBreadcrumbs) {
      breadcrumbs.removeAt(0);
    }
  }

  @override
  void setUserContext({String? userId, bool isGuest = false}) {
    this.userId = userId;
    this.isGuest = isGuest;
  }

  @override
  void setCustomKey(String key, String value) {
    customKeys[key] = _sanitizer.scrub(value);
  }
}

class RecordedError {
  const RecordedError({
    required this.message,
    required this.fatal,
    this.reason,
    this.stack,
  });

  final String message;
  final String? reason;
  final bool fatal;
  final StackTrace? stack;
}
