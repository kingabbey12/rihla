/// Sanitized diagnostic bundle attached to feedback when the user consents.
class SupportBundle {
  const SupportBundle({
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.featureFlags,
    required this.generatedAt,
    this.navigationLogs = const [],
    this.aiLogs = const [],
    this.crashIdentifiers = const [],
    this.performanceMetrics = const {},
  });

  final String appVersion;
  final String buildNumber;
  final String platform;
  final String osVersion;
  final String deviceModel;
  final Map<String, String> featureFlags;
  final DateTime generatedAt;
  final List<String> navigationLogs;
  final List<String> aiLogs;
  final List<String> crashIdentifiers;
  final Map<String, String> performanceMetrics;

  Map<String, String> toFlatMap() => {
        'app_version': appVersion,
        'build_number': buildNumber,
        'platform': platform,
        'os_version': osVersion,
        'device_model': deviceModel,
        'generated_at': generatedAt.toIso8601String(),
        ...featureFlags.map((k, v) => MapEntry('flag_$k', v)),
        ...performanceMetrics.map((k, v) => MapEntry('perf_$k', v)),
        if (navigationLogs.isNotEmpty)
          'navigation_log_count': '${navigationLogs.length}',
        if (aiLogs.isNotEmpty) 'ai_log_count': '${aiLogs.length}',
        if (crashIdentifiers.isNotEmpty)
          'crash_ids': crashIdentifiers.join(','),
      };
}
