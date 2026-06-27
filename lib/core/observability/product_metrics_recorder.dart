import 'package:rihla/core/observability/analytics_event.dart';

/// Optional hook for on-device beta dashboard counters.
abstract class ProductMetricsRecorder {
  Future<void> record(AnalyticsEvent event);
}

class NoOpProductMetricsRecorder implements ProductMetricsRecorder {
  const NoOpProductMetricsRecorder();

  @override
  Future<void> record(AnalyticsEvent event) async {}
}
