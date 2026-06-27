import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/uae/domain/entities/uae_alert_type.dart';
import 'package:rihla/features/uae/presentation/providers/uae_providers.dart';

/// Navigation overlay for UAE-specific alerts.
class UaeAlertBanner extends ConsumerWidget {
  const UaeAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(uaeIntelligenceSnapshotProvider);
    final snapshot = snapshotAsync.value;
    if (snapshot == null || snapshot.alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    final alert = snapshot.alerts.first;
    final color = switch (alert.type) {
      UaeAlertType.salik => Colors.amber.shade800,
      UaeAlertType.speedCamera => Colors.red.shade700,
      UaeAlertType.weather => Colors.blue.shade700,
      UaeAlertType.holidayTraffic => Colors.orange.shade800,
      _ => Colors.grey.shade700,
    };

    return Material(
      color: color,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(_iconFor(alert.type), color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    alert.title,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    alert.message,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(UaeAlertType type) => switch (type) {
        UaeAlertType.salik => Icons.toll,
        UaeAlertType.speedCamera => Icons.speed,
        UaeAlertType.weather => Icons.cloud,
        UaeAlertType.holidayTraffic => Icons.event,
        UaeAlertType.drivingRule => Icons.rule,
        UaeAlertType.roadEvent => Icons.construction,
      };
}
