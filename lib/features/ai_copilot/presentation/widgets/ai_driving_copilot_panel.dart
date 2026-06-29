import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation_type.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_response.dart';
import 'package:rihla/features/ai_copilot/domain/models/ai_copilot_state.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_gradient_orb.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_recommendation_cards.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_streaming_text.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

typedef _QuickAction = ({IconData icon, String label});

const _kQuickActions = <_QuickAction>[
  (icon: Icons.alt_route_rounded, label: 'Explain route'),
  (icon: Icons.traffic_rounded, label: 'Avoid traffic'),
  (icon: Icons.local_gas_station_rounded, label: 'Find fuel'),
  (icon: Icons.local_cafe_rounded, label: 'Nearest coffee'),
  (icon: Icons.health_and_safety_rounded, label: 'Emergency help'),
];

/// Floating, expandable Driving Copilot — active during navigation.
class AiDrivingCopilotPanel extends ConsumerStatefulWidget {
  const AiDrivingCopilotPanel({
    required this.expanded,
    required this.onToggle,
    super.key,
  });

  final bool expanded;
  final VoidCallback onToggle;

  @override
  ConsumerState<AiDrivingCopilotPanel> createState() =>
      _AiDrivingCopilotPanelState();
}

class _AiDrivingCopilotPanelState
    extends ConsumerState<AiDrivingCopilotPanel> {
  void _onQuickAction(String label) {
    HapticFeedback.selectionClick();
    if (label == 'Avoid traffic') {
      ref.read(navigationSessionControllerProvider.notifier).retryReroute();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — on it.')),
    );
  }

  void _onRecAction(AiRecommendation rec) {
    if (rec.type == AiRecommendationType.reroute) {
      ref.read(navigationSessionControllerProvider.notifier).retryReroute();
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiControllerProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    if (aiState is AiCopilotOffline) {
      return Positioned(
        right: 16,
        bottom: 168 + bottom,
        child: const _OfflineChip(),
      );
    }

    final loading = aiState is AiCopilotLoading &&
        aiState.mode == AiCopilotMode.drivingCopilot;

    if (aiState is! AiCopilotDrivingReady && !loading) {
      return const SizedBox.shrink();
    }

    if (!widget.expanded) {
      return Positioned(
        right: 16,
        bottom: 168 + bottom,
        child: _CopilotFab(loading: loading, onPressed: widget.onToggle),
      );
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 100 + bottom,
      child: AiDrivingCopilotContent(
        response: aiState is AiCopilotDrivingReady ? aiState.response : null,
        onClose: widget.onToggle,
        onQuickAction: _onQuickAction,
        onRecAction: _onRecAction,
      ),
    );
  }
}

/// Premium driving copilot card content (glass panel). Driven by an explicit
/// [response] so it can be composed directly for verification screenshots.
class AiDrivingCopilotContent extends StatefulWidget {
  const AiDrivingCopilotContent({
    required this.response,
    required this.onClose,
    super.key,
    this.onQuickAction,
    this.onRecAction,
    this.maxHeightFactor = 0.5,
    this.streamSummary = true,
  });

  final AiResponse? response;
  final VoidCallback onClose;
  final ValueChanged<String>? onQuickAction;
  final void Function(AiRecommendation recommendation)? onRecAction;
  final double maxHeightFactor;
  final bool streamSummary;

  @override
  State<AiDrivingCopilotContent> createState() =>
      _AiDrivingCopilotContentState();
}

class _AiDrivingCopilotContentState extends State<AiDrivingCopilotContent> {
  bool _listening = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final response = widget.response;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.82 : 0.96,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: RihlaReferenceTokens.floatingShadow(opacity: 0.18),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.sizeOf(context).height * widget.maxHeightFactor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PanelHeader(
                  listening: _listening,
                  onMic: () => setState(() => _listening = !_listening),
                  onClose: widget.onClose,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (response != null)
                          AiStreamingText(
                            text: response.summary,
                            stream: widget.streamSummary,
                          ),
                        const SizedBox(height: 14),
                        _QuickActionsRow(
                          actions: _kQuickActions,
                          onTap: (label) => widget.onQuickAction?.call(label),
                        ),
                        const SizedBox(height: 14),
                        if (response != null)
                          AiRecommendationCards(
                            recommendations: response.recommendations,
                            onAction: widget.onRecAction == null
                                ? null
                                : (rec) => widget.onRecAction!(rec),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.listening,
    required this.onMic,
    required this.onClose,
  });

  final bool listening;
  final VoidCallback onMic;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const teal = RihlaReferenceTokens.mapTeal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Row(
        children: [
          const AiGradientOrb(size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.aiDrivingCopilotTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: listening ? teal : theme.colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      listening ? 'Listening…' : 'Active · watching the road',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMic,
            icon: Icon(listening ? Icons.graphic_eq_rounded : Icons.mic_rounded),
            color: teal,
            tooltip: 'Voice',
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions, required this.onTap});

  final List<_QuickAction> actions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in actions)
          ActionChip(
            avatar: Icon(a.icon, size: 18, color: theme.colorScheme.primary),
            label: Text(a.label),
            onPressed: () => onTap(a.label),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }
}

class _OfflineChip extends StatelessWidget {
  const _OfflineChip();

  @override
  Widget build(BuildContext context) {
    return const Chip(
      avatar: Icon(Icons.cloud_off, size: 18),
      label: Text('AI unavailable while offline.'),
    );
  }
}

class _CopilotFab extends StatelessWidget {
  const _CopilotFab({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
            boxShadow: RihlaReferenceTokens.floatingShadow(opacity: 0.22),
          ),
          child: loading
              ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : const AiGradientOrb(size: 48),
        ),
      ),
    );
  }
}
