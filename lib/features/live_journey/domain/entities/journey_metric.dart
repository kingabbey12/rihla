import 'package:rihla/features/live_journey/domain/entities/metric_source.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_status.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_update_method.dart';

/// A single live metric with metadata required by the metrics engine.
class JourneyMetric<T> {
  const JourneyMetric({
    required this.value,
    required this.status,
    required this.timestamp,
    required this.source,
    required this.updateMethod,
  });

  final T value;
  final MetricStatus status;
  final DateTime timestamp;
  final MetricSource source;
  final MetricUpdateMethod updateMethod;

  JourneyMetric<T> copyWith({
    T? value,
    MetricStatus? status,
    DateTime? timestamp,
    MetricSource? source,
    MetricUpdateMethod? updateMethod,
  }) {
    return JourneyMetric<T>(
      value: value ?? this.value,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      updateMethod: updateMethod ?? this.updateMethod,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyMetric<T> &&
          value == other.value &&
          status == other.status &&
          timestamp == other.timestamp &&
          source == other.source &&
          updateMethod == other.updateMethod;

  @override
  int get hashCode =>
      Object.hash(value, status, timestamp, source, updateMethod);
}
