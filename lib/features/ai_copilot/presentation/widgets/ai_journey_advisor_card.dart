import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_response.dart';
import 'package:rihla/features/ai_copilot/domain/models/ai_copilot_state.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_gradient_orb.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_recommendation_cards.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_streaming_text.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_typing_indicator.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Premium Journey Advisor — shown before navigation starts.
class AiJourneyAdvisorCard extends ConsumerWidget {
  const AiJourneyAdvisorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiControllerProvider);

    return switch (aiState) {
      AiCopilotLoading(:final mode) when mode == AiCopilotMode.journeyAdvisor =>
        _Shell(child: _Loading(label: context.l10n.aiAdvisorLoading)),
      AiCopilotAdvisorReady(:final response) => AiJourneyAdvisorContent(
          response: response,
          onAction: (rec) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(rec.title)),
            );
          },
        ),
      AiCopilotError(:final message) => _Shell(child: _ErrorBody(message: message)),
      AiCopilotOffline() => _Shell(child: const _OfflineBody()),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Premium advisor content, driven by an explicit [AiResponse] so it can be
/// composed directly (e.g. for verification screenshots).
class AiJourneyAdvisorContent extends StatelessWidget {
  const AiJourneyAdvisorContent({
    required this.response,
    super.key,
    this.onAction,
    this.streamSummary = true,
  });

  final AiResponse response;
  final void Function(dynamic recommendation)? onAction;
  final bool streamSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(title: context.l10n.aiJourneyAdvisorTitle),
          const SizedBox(height: 14),
          AiStreamingText(text: response.summary, stream: streamSummary),
          if (response.highlights.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final h in response.highlights)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: RihlaReferenceTokens.mapTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        h,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),
          AiRecommendationCards(
            recommendations: response.recommendations,
            onAction: onAction == null ? null : (rec) => onAction!(rec),
          ),
        ],
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const AiGradientOrb(size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Personalised for your trip',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const _LiveBadge(),
      ],
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const teal = RihlaReferenceTokens.mapTeal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 12, color: teal),
          const SizedBox(width: 3),
          Text(
            'AI',
            style: theme.textTheme.labelSmall?.copyWith(
              color: teal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const AiGradientOrb(size: 40),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const AiTypingIndicator(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _OfflineBody extends StatelessWidget {
  const _OfflineBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.cloud_off_rounded, color: theme.colorScheme.outline),
        const SizedBox(width: 10),
        const Expanded(child: Text('AI is unavailable while offline.')),
      ],
    );
  }
}
