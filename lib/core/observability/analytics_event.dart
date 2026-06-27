/// Canonical product analytics events.
///
/// Keep this list closed so dashboards and funnels stay stable across releases.
enum AnalyticsEvent {
  appOpened('app_opened'),
  journeyStarted('journey_started'),
  journeyCompleted('journey_completed'),
  navigationCancelled('navigation_cancelled'),
  emergencyActivated('emergency_activated'),
  offlineDownload('offline_download'),
  exploreUsed('explore_used'),
  aiUsed('ai_used'),
  searchSuccess('search_success'),
  searchFailure('search_failure');

  const AnalyticsEvent(this.name);

  /// Stable wire name sent to analytics backends.
  final String name;
}
