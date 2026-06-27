import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/observability/analytics_event.dart';
import 'package:rihla/core/observability/analytics_service.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/core/observability/product_metrics_recorder.dart';

final productMetricsRecorderProvider = Provider<ProductMetricsRecorder>(
  (ref) => const NoOpProductMetricsRecorder(),
);

/// Logs a product event to analytics and the optional metrics recorder.
void trackProductEvent(
  Ref ref,
  AnalyticsEvent event, {
  Map<String, String> properties = const {},
}) {
  ref.read(analyticsServiceProvider).logEvent(event, properties: properties);
  ref.read(productMetricsRecorderProvider).record(event);
}
