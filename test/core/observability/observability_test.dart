import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/observability/analytics_event.dart';
import 'package:rihla/core/observability/analytics_service.dart';
import 'package:rihla/core/observability/app_logger.dart';
import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/crash_reporter.dart';

void main() {
  group('BufferingAnalyticsService', () {
    test('records events with sanitized properties', () {
      final analytics = BufferingAnalyticsService();
      analytics.logEvent(
        AnalyticsEvent.journeyStarted,
        properties: {'email': 'a@b.com', 'origin': 'home'},
      );
      expect(analytics.events, hasLength(1));
      expect(analytics.events.first.event, AnalyticsEvent.journeyStarted);
      expect(analytics.events.first.properties['email'], '[redacted]');
      expect(analytics.events.first.properties['origin'], 'home');
    });

    test('reset clears buffered state', () {
      final analytics = BufferingAnalyticsService()
        ..logEvent(AnalyticsEvent.aiUsed)
        ..identify(userId: 'u1');
      analytics.reset();
      expect(analytics.events, isEmpty);
      expect(analytics.userId, isNull);
    });
  });

  group('CompositeAnalyticsService', () {
    test('fans out to all delegates', () {
      final a = BufferingAnalyticsService();
      final b = BufferingAnalyticsService();
      final composite = CompositeAnalyticsService([a, b]);
      composite.logEvent(AnalyticsEvent.searchSuccess);
      expect(a.events, hasLength(1));
      expect(b.events, hasLength(1));
    });
  });

  group('BufferingCrashReporter', () {
    test('records non-fatal with sanitized message', () {
      final reporter = BufferingCrashReporter();
      reporter.recordNonFatal(
        Exception('failed for user@example.com'),
        StackTrace.current,
        reason: 'token Bearer abcdef123456',
      );
      expect(reporter.errors, hasLength(1));
      expect(reporter.errors.first.fatal, isFalse);
      expect(reporter.errors.first.message, contains('[redacted-email]'));
      expect(reporter.errors.first.reason, contains('[redacted-token]'));
    });

    test('caps breadcrumb trail at maxBreadcrumbs', () {
      final reporter = BufferingCrashReporter(maxBreadcrumbs: 3);
      for (var i = 0; i < 10; i++) {
        reporter.addBreadcrumb(Breadcrumb(message: 'step $i'));
      }
      expect(reporter.breadcrumbs, hasLength(3));
      expect(reporter.breadcrumbs.last.message, 'step 9');
    });
  });

  group('AppLogger', () {
    test('writes breadcrumbs into the crash reporter', () {
      final reporter = BufferingCrashReporter();
      final logger = AppLogger(crashReporter: reporter);
      logger.log(
        'navigation_started',
        category: ObservabilityCategory.navigation,
      );
      expect(reporter.breadcrumbs, hasLength(1));
      expect(reporter.breadcrumbs.first.category,
          ObservabilityCategory.navigation);
    });

    test('records errors and sanitizes network logs', () {
      final reporter = BufferingCrashReporter();
      final logger = AppLogger(crashReporter: reporter);
      logger.error(Exception('boom'), StackTrace.current);
      logger.rawNetworkLog('GET https://api/x token Bearer abcdef123456');
      expect(reporter.errors, hasLength(1));
      expect(
        reporter.breadcrumbs.any((b) => b.message.contains('[redacted-token]')),
        isTrue,
      );
    });
  });
}
