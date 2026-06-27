import 'package:flutter/foundation.dart';
import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/crash_reporter.dart';
import 'package:rihla/core/observability/log_sanitizer.dart';

/// Single secure logging entry point for the app.
///
/// Every log is sanitized, mirrored to the crash reporter as a breadcrumb, and
/// (in debug only) printed to the console. Production has no raw console output.
class AppLogger {
  AppLogger({
    required CrashReporter crashReporter,
    LogSanitizer sanitizer = const LogSanitizer(),
  })  : _crashReporter = crashReporter,
        _sanitizer = sanitizer;

  final CrashReporter _crashReporter;
  final LogSanitizer _sanitizer;

  void log(
    String message, {
    ObservabilityCategory category = ObservabilityCategory.app,
    ObservabilityLevel level = ObservabilityLevel.info,
    Map<String, String> data = const {},
  }) {
    final crumb = Breadcrumb(
      message: message,
      category: category,
      level: level,
      data: data,
    );
    _crashReporter.addBreadcrumb(crumb);
    if (kDebugMode) {
      // ignore: avoid_print
      debugPrint('RIHLA ${crumb.toString()}');
    }
  }

  void breadcrumb(
    String message, {
    ObservabilityCategory category = ObservabilityCategory.app,
    Map<String, String> data = const {},
  }) =>
      log(message, category: category, data: data);

  /// Routes raw network/log callback strings through the sanitizer.
  void rawNetworkLog(String message) {
    log(
      _sanitizer.scrub(message),
      category: ObservabilityCategory.network,
      level: ObservabilityLevel.debug,
    );
  }

  void error(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    if (fatal) {
      _crashReporter.recordFatal(error, stack, reason: reason);
    } else {
      _crashReporter.recordNonFatal(error, stack, reason: reason);
    }
    if (kDebugMode) {
      debugPrint('RIHLA error: ${_sanitizer.scrub(error.toString())}');
    }
  }
}
