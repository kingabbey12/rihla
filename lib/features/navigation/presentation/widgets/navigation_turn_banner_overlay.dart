import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/navigation/presentation/widgets/navigation_turn_banner.dart';

/// Map overlay for the turn-by-turn banner during active navigation.
class NavigationTurnBannerOverlay extends ConsumerWidget {
  const NavigationTurnBannerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(navigationSessionControllerProvider);
    if (state is! NavigationSessionActive) return const SizedBox.shrink();

    final session = state.session;
    if (session.status != NavigationStatus.navigating &&
        session.status != NavigationStatus.rerouting) {
      return const SizedBox.shrink();
    }

    return NavigationTurnBanner(
      session: session,
      onToggleVoice: () {
        final enabled = !session.voiceEnabled;
        ref.read(navigationSessionControllerProvider.notifier).setVoiceEnabled(
              enabled,
            );
      },
    );
  }
}
