import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_message_role.dart';
import 'package:rihla/features/ai_copilot/presentation/pages/ai_conversation_page.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_gradient_orb.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_suggestion_card.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

typedef _Suggestion = ({
  IconData icon,
  String title,
  String subtitle,
  String prompt,
  List<Color> gradient,
});

/// Premium AI entry — greeting, suggested actions, and recent conversations.
class AiHomePage extends ConsumerWidget {
  const AiHomePage({super.key});

  static const _suggestions = <_Suggestion>[
    (
      icon: Icons.navigation_rounded,
      title: 'Plan a journey',
      subtitle: 'Best route & departure time',
      prompt: 'Plan the best journey for me right now',
      gradient: [Color(0xFF1FB6A6), Color(0xFF31C5C7)],
    ),
    (
      icon: Icons.traffic_rounded,
      title: 'Avoid traffic',
      subtitle: 'Live congestion ahead',
      prompt: 'How is traffic and can you help me avoid it?',
      gradient: [Color(0xFFF57C00), Color(0xFFFFB300)],
    ),
    (
      icon: Icons.local_gas_station_rounded,
      title: 'Find fuel or charging',
      subtitle: 'Closest stations nearby',
      prompt: 'Find the nearest fuel or charging station',
      gradient: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    ),
    (
      icon: Icons.local_cafe_rounded,
      title: 'Nearest coffee',
      subtitle: 'Take a break',
      prompt: 'Find me a good coffee nearby',
      gradient: [Color(0xFF8D6E63), Color(0xFFBCAAA4)],
    ),
    (
      icon: Icons.health_and_safety_rounded,
      title: 'Emergency help',
      subtitle: 'Get assistance fast',
      prompt: 'I need emergency help',
      gradient: [Color(0xFFE53935), Color(0xFFFF6F60)],
    ),
  ];

  void _openChat(BuildContext context, {String? prompt, bool voice = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiConversationPage(
          initialPrompt: prompt,
          startVoice: voice,
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final conversation = ref.watch(aiRepositoryProvider).current;
    final lastAssistant = conversation?.messages
        .where((m) => m.role == AiMessageRole.assistant)
        .map((m) => m.content)
        .lastOrNull;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Rihla AI'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(child: const AiGradientOrb(size: 76)),
          const SizedBox(height: 20),
          Text(
            _greeting(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How can I help you today?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          _AskBar(
            onTap: () => _openChat(context),
            onMic: () => _openChat(context, voice: true),
          ),
          const SizedBox(height: 28),
          Text(
            'Suggested',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final s in _suggestions) ...[
            AiSuggestionCard(
              icon: s.icon,
              title: s.title,
              subtitle: s.subtitle,
              gradient: s.gradient,
              onTap: () => _openChat(context, prompt: s.prompt),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          Text(
            'Recent',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (lastAssistant != null)
            _RecentCard(
              snippet: lastAssistant,
              mode: conversation!.mode.name,
              onTap: () => _openChat(context),
            )
          else
            _EmptyRecent(onTap: () => _openChat(context)),
        ],
      ),
    );
  }
}

class _AskBar extends StatelessWidget {
  const _AskBar({required this.onTap, required this.onMic});

  final VoidCallback onTap;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const teal = RihlaReferenceTokens.mapTeal;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: RihlaReferenceTokens.floatingShadow(opacity: 0.08),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(Icons.auto_awesome_rounded, color: teal, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ask anything…',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                onPressed: onMic,
                icon: const Icon(Icons.mic_rounded),
                color: teal,
                tooltip: 'Voice',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.snippet,
    required this.mode,
    required this.onTap,
  });

  final String snippet;
  final String mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              const AiGradientOrb(size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continue conversation',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.forum_outlined,
              color: theme.colorScheme.onSurfaceVariant, size: 32),
          const SizedBox(height: 10),
          Text(
            'No conversations yet',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start a chat and it will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onTap,
            child: const Text('Start a conversation'),
          ),
        ],
      ),
    );
  }
}
