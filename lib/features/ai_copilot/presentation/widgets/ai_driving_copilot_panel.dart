import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation_type.dart';
import 'package:rihla/features/ai_copilot/domain/models/ai_copilot_state.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_insight_card.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_recommendation_list.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';

/// Driving Copilot panel — active during navigation.
class AiDrivingCopilotPanel extends ConsumerWidget {
  const AiDrivingCopilotPanel({
    required this.expanded,
    required this.onToggle,
    super.key,
  });

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aiState = ref.watch(aiControllerProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    if (aiState is AiCopilotLoading &&
        aiState.mode == AiCopilotMode.drivingCopilot) {
      return Positioned(
        right: 16,
        bottom: 168 + bottom,
        child: _Fab(loading: true, onPressed: onToggle),
      );
    }

    if (aiState is! AiCopilotDrivingReady) {
      return const SizedBox.shrink();
    }

    if (!expanded) {
      return Positioned(
        right: 16,
        bottom: 168 + bottom,
        child: _Fab(loading: false, onPressed: onToggle),
      );
    }

    final response = aiState.response;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 100 + bottom,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                title: Text(context.l10n.aiDrivingCopilotTitle),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onToggle,
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      AiInsightCard(
                        title: context.l10n.aiDrivingCopilotTitle,
                        response: response,
                        icon: Icons.support_agent,
                      ),
                      const SizedBox(height: 12),
                      AiRecommendationList(
                        recommendations: response.recommendations,
                        onAction: (rec) {
                          if (rec.type == AiRecommendationType.reroute) {
                            ref
                                .read(navigationSessionControllerProvider.notifier)
                                .retryReroute();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
      heroTag: 'ai_copilot_fab',
      onPressed: onPressed,
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundColor: theme.colorScheme.onPrimaryContainer,
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(context.l10n.aiCopilotOpen),
    );
  }
}
