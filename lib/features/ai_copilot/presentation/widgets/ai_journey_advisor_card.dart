import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/models/ai_copilot_state.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_insight_card.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_recommendation_list.dart';

/// Journey Advisor — shown before navigation starts.
class AiJourneyAdvisorCard extends ConsumerWidget {
  const AiJourneyAdvisorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiControllerProvider);

    return switch (aiState) {
      AiCopilotLoading(:final mode)
          when mode == AiCopilotMode.journeyAdvisor =>
        _LoadingCard(label: context.l10n.aiAdvisorLoading),
      AiCopilotAdvisorReady(:final response) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AiInsightCard(
              title: context.l10n.aiJourneyAdvisorTitle,
              response: response,
            ),
            const SizedBox(height: 12),
            AiRecommendationList(
              recommendations: response.recommendations,
              onAction: (rec) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(rec.title)),
                );
              },
            ),
            if (response.fromMock)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.l10n.aiEnginePowered,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ),
      AiCopilotError(:final message) => _ErrorCard(message: message),
      AiCopilotOffline() => _OfflineCard(),
      _ => const SizedBox.shrink(),
    };
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(message, style: theme.textTheme.bodySmall),
      ),
    );
  }
}

class _OfflineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: theme.colorScheme.outline),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('AI unavailable while offline.'),
            ),
          ],
        ),
      ),
    );
  }
}
