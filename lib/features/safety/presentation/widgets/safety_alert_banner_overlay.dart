import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/safety/presentation/providers/safety_providers.dart';
import 'package:rihla/features/safety/presentation/widgets/safety_alert_banner.dart';

/// Map overlay for critical safety alerts.
class SafetyAlertBannerOverlay extends ConsumerWidget {
  const SafetyAlertBannerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationSessionControllerProvider);
    if (navState is! NavigationSessionActive) return const SizedBox.shrink();

    final alert = ref.watch(safetyPrimaryAlertProvider);
    if (alert == null || !ref.watch(safetyHasCriticalAlertProvider)) {
      return const SizedBox.shrink();
    }

    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: top + 168,
      left: 12,
      right: 12,
      child: SafetyAlertBanner(hazard: alert),
    );
  }
}
