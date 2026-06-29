import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/ai_copilot/domain/models/ai_copilot_state.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_journey_review_body.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_typing_indicator.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';

/// Journey Review — shown after arrival.
class AiJourneyReviewSheet extends ConsumerWidget {
  const AiJourneyReviewSheet({
    required this.onDismiss,
    super.key,
  });

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aiState = ref.watch(aiControllerProvider);

    if (aiState is! AiCopilotReviewReady && aiState is! AiCopilotLoading) {
      return const SizedBox.shrink();
    }

    final session = ref.watch(navigationSessionProvider);
    final journeyScore = session?.route.journeyScore.round() ?? 88;
    final safetyScore =
        session?.safety.assessment.overallSafetyScore.round() ?? 92;
    final drivingScore =
        session?.safety.assessment.driverAlertness.round() ?? 85;
    final distanceKm = session?.route.distanceKm ?? 18.5;
    final durationMinutes = session != null
        ? DateTime.now().difference(session.startedAt).inMinutes.clamp(0, 1 << 30)
        : 24;
    final fuelLiters = distanceKm * 0.08;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: switch (aiState) {
                  AiCopilotLoading() => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AiTypingIndicator(),
                          const SizedBox(height: 12),
                          Text(context.l10n.aiReviewLoading),
                        ],
                      ),
                    ),
                  AiCopilotReviewReady(:final response) => AiJourneyReviewBody(
                      scrollController: scrollController,
                      summary: response.summary,
                      highlights: response.highlights,
                      recommendations: response.recommendations,
                      journeyScore: journeyScore,
                      safetyScore: safetyScore,
                      drivingScore: drivingScore,
                      distanceKm: distanceKm,
                      durationMinutes: durationMinutes,
                      fuelLiters: fuelLiters,
                      onShare: () {
                        final export = ref
                            .read(aiControllerProvider.notifier)
                            .exportConversation();
                        if (export != null) {
                          Clipboard.setData(ClipboardData(text: export));
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Journey summary copied to share'),
                          ),
                        );
                      },
                      onSave: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Journey review saved')),
                        );
                      },
                      onDone: onDismiss,
                    ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
