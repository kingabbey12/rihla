import 'package:rihla/core/observability/analytics_event.dart';
import 'package:rihla/core/observability/product_metrics_recorder.dart';
import 'package:rihla/features/beta_feedback/data/services/beta_metrics_service.dart';

class BetaMetricsServiceRecorder implements ProductMetricsRecorder {
  BetaMetricsServiceRecorder(this._metrics);

  final BetaMetricsService _metrics;

  @override
  Future<void> record(AnalyticsEvent event) => _metrics.recordEvent(event);
}
