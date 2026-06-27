import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/ai_copilot/domain/models/ai_copilot_state.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_insight_card.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_recommendation_list.dart';
import 'package:rihla/shared/widgets/premium_buttons.dart';

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

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.fact_check_outlined,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.aiJourneyReviewTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (aiState) {
                  AiCopilotLoading() => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(context.l10n.aiReviewLoading),
                        ],
                      ),
                    ),
                  AiCopilotReviewReady(:final response) => ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        AiInsightCard(
                          title: context.l10n.aiJourneyReviewTitle,
                          response: response,
                          icon: Icons.insights_outlined,
                        ),
                        const SizedBox(height: 16),
                        AiRecommendationList(
                          recommendations: response.recommendations,
                        ),
                        const SizedBox(height: 20),
                        PremiumPrimaryButton(
                          label: context.l10n.aiReviewDone,
                          onPressed: onDismiss,
                        ),
                      ],
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
