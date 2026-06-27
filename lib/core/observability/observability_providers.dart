import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/observability/analytics_service.dart';
import 'package:rihla/core/observability/app_logger.dart';
import 'package:rihla/core/observability/crash_reporter.dart';
import 'package:rihla/core/observability/log_sanitizer.dart';
import 'package:rihla/core/observability/posthog_analytics_service.dart';

final logSanitizerProvider = Provider<LogSanitizer>(
  (ref) => const LogSanitizer(),
);

/// Crash reporter — Crashlytics in production (wired in [main]), no-op default.
///
/// Overridden in [main] when `CRASH_REPORTING_ENABLED=true`.
final crashReporterProvider = Provider<CrashReporter>(
  (ref) => const NoOpCrashReporter(),
);

/// Analytics — PostHog/Firebase when enabled; no-op by default for privacy.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  if (ApiConfig.posthogEnabled) {
    return CompositeAnalyticsService([
      PostHogAnalyticsService(
        apiKey: ApiConfig.posthogApiKey!,
        host: ApiConfig.posthogHost,
        sanitizer: ref.watch(logSanitizerProvider),
      ),
    ]);
  }
  return const NoOpAnalyticsService();
});

final appLoggerProvider = Provider<AppLogger>(
  (ref) => AppLogger(
    crashReporter: ref.watch(crashReporterProvider),
    sanitizer: ref.watch(logSanitizerProvider),
  ),
);
