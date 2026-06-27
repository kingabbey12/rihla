import 'package:flutter/material.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_status.dart';

/// Small status dot reflecting metric health (good / warning / critical).
class LiveMetricStatusIndicator extends StatelessWidget {
  const LiveMetricStatusIndicator({
    required this.status,
    super.key,
  });

  final MetricStatus status;

  Color _color(ColorScheme scheme) => switch (status) {
        MetricStatus.good => scheme.primary,
        MetricStatus.warning => scheme.tertiary,
        MetricStatus.critical => scheme.error,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _color(scheme),
        shape: BoxShape.circle,
      ),
    );
  }
}
