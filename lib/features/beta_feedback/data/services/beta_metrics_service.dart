import 'dart:convert';

import 'package:rihla/core/observability/analytics_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local beta metrics aggregator for the closed-beta dashboard.
///
/// Records session and funnel counters on-device. Sync to PostHog/Firebase
/// separately via analytics; this store powers the weekly beta report template.
class BetaMetricsService {
  BetaMetricsService(this._prefs);

  final SharedPreferences _prefs;
  static const _prefix = 'beta_metrics_';

  String _dayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _weekKey() {
    final now = DateTime.now();
    final week = now.difference(DateTime(now.year)).inDays ~/ 7;
    return '${now.year}-W$week';
  }

  Future<void> recordSession() async {
    await _increment('sessions_${_dayKey()}');
    await _increment('sessions_week_${_weekKey()}');
  }

  Future<void> recordEvent(AnalyticsEvent event) async {
    await _increment('event_${event.name}_${_dayKey()}');
    switch (event) {
      case AnalyticsEvent.journeyStarted:
        await _increment('journeys_started_${_dayKey()}');
      case AnalyticsEvent.journeyCompleted:
        await _increment('journeys_completed_${_dayKey()}');
      case AnalyticsEvent.navigationCancelled:
        await _increment('nav_cancelled_${_dayKey()}');
      case AnalyticsEvent.emergencyActivated:
        await _increment('emergency_${_dayKey()}');
      case AnalyticsEvent.offlineDownload:
        await _increment('offline_dl_${_dayKey()}');
      case AnalyticsEvent.exploreUsed:
        await _increment('explore_${_dayKey()}');
      case AnalyticsEvent.aiUsed:
        await _increment('ai_${_dayKey()}');
      case AnalyticsEvent.searchSuccess:
        await _increment('search_ok_${_dayKey()}');
      case AnalyticsEvent.searchFailure:
        await _increment('search_fail_${_dayKey()}');
      case AnalyticsEvent.appOpened:
        break;
    }
  }

  Future<void> recordCrashFreeSession() async {
    await _increment('crash_free_${_dayKey()}');
  }

  Future<void> recordCloudSyncSuccess() async {
    await _increment('cloud_sync_ok_${_dayKey()}');
  }

  Future<void> recordCloudSyncFailure() async {
    await _increment('cloud_sync_fail_${_dayKey()}');
  }

  Future<void> _increment(String key) async {
    final full = '$_prefix$key';
    await _prefs.setInt(full, (_prefs.getInt(full) ?? 0) + 1);
  }

  int getCounter(String key) => _prefs.getInt('$_prefix$key') ?? 0;

  /// Snapshot for the weekly beta report.
  Map<String, dynamic> dailySnapshot() {
    final day = _dayKey();
    final started = getCounter('journeys_started_$day');
    final completed = getCounter('journeys_completed_$day');
    final cancelled = getCounter('nav_cancelled_$day');
    final sessions = getCounter('sessions_$day');
    final crashFree = getCounter('crash_free_$day');
    final completionRate = started == 0 ? 0.0 : completed / started;
    final cancelRate = started == 0 ? 0.0 : cancelled / started;
    final crashFreeRate = sessions == 0 ? 1.0 : crashFree / sessions;

    return {
      'date': day,
      'dau_sessions': sessions,
      'journeys_started': started,
      'journeys_completed': completed,
      'journey_completion_rate': completionRate,
      'navigation_cancel_rate': cancelRate,
      'crash_free_session_rate': crashFreeRate,
      'ai_usage': getCounter('ai_$day'),
      'emergency_usage': getCounter('emergency_$day'),
      'offline_downloads': getCounter('offline_dl_$day'),
      'explore_usage': getCounter('explore_$day'),
      'cloud_sync_success': getCounter('cloud_sync_ok_$day'),
      'cloud_sync_failure': getCounter('cloud_sync_fail_$day'),
      'search_success': getCounter('search_ok_$day'),
      'search_failure': getCounter('search_fail_$day'),
    };
  }

  String exportJson() => jsonEncode(dailySnapshot());
}
