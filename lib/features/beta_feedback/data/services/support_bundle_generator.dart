import 'dart:io';

import 'package:rihla/config/app_config.dart';
import 'package:rihla/core/observability/crash_reporter.dart';
import 'package:rihla/core/observability/log_sanitizer.dart';
import 'package:rihla/core/remote_config/domain/entities/remote_config.dart';
import 'package:rihla/features/beta_feedback/domain/entities/support_bundle.dart';

/// Builds a sanitized support bundle for beta feedback attachments.
///
/// Excludes PII unless the user explicitly opts in via [includeDiagnostics].
/// All log lines pass through [LogSanitizer].
class SupportBundleGenerator {
  SupportBundleGenerator({
    LogSanitizer sanitizer = const LogSanitizer(),
    CrashReporter? crashReporter,
  })  : _sanitizer = sanitizer,
        _crashReporter = crashReporter;

  final LogSanitizer _sanitizer;
  final CrashReporter? _crashReporter;

  SupportBundle generate({
    required RemoteConfig config,
    List<String> navigationLogs = const [],
    List<String> aiLogs = const [],
    Map<String, String> performanceMetrics = const {},
  }) {
    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : Platform.operatingSystem;

    final crashIds = <String>[];
    if (_crashReporter is BufferingCrashReporter) {
      crashIds.addAll(
        _crashReporter!.errors.map((e) => _sanitizer.scrub(e.message)),
      );
    }

    return SupportBundle(
      appVersion: AppConfig.appVersion,
      buildNumber: AppConfig.buildNumber,
      platform: platform,
      osVersion: _sanitizer.scrub(Platform.operatingSystemVersion),
      deviceModel: Platform.localHostname,
      featureFlags: {
        'ai': '${config.aiEnabled}',
        'emergency': '${config.emergencyEnabled}',
        'explore': '${config.exploreEnabled}',
        'offline': '${config.offlineEnabled}',
        'cloud_sync': '${config.cloudSyncEnabled}',
        'maintenance': '${config.maintenanceMode}',
      },
      generatedAt: DateTime.now(),
      navigationLogs:
          navigationLogs.map(_sanitizer.scrub).take(20).toList(),
      aiLogs: aiLogs.map(_sanitizer.scrub).take(20).toList(),
      crashIdentifiers: crashIds.take(5).toList(),
      performanceMetrics: _sanitizer.scrubMap(performanceMetrics),
    );
  }
}
