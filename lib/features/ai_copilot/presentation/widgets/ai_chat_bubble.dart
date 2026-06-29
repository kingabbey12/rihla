import 'package:flutter/material.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_gradient_orb.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_markdown_text.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_streaming_text.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_typing_indicator.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// A single chat turn — user (right) or assistant (left) — with a soft slide +
/// fade entrance, optional avatar, timestamp, and streaming/typing states.
class AiChatBubble extends StatelessWidget {
  const AiChatBubble({
    required this.text,
    required this.isUser,
    super.key,
    this.timestamp,
    this.showAvatar = true,
    this.streaming = false,
    this.typing = false,
    this.onStreamComplete,
  });

  final String text;
  final bool isUser;
  final DateTime? timestamp;
  final bool showAvatar;
  final bool streaming;
  final bool typing;
  final VoidCallback? onStreamComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    const teal = RihlaReferenceTokens.mapTeal;

    final bubbleColor = isUser
        ? teal
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85);
    final textColor =
        isUser ? Colors.white : theme.colorScheme.onSurface;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isUser ? 20 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 20),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset((isUser ? 16 : -16) * (1 - t), 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: align,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser && showAvatar) ...[
                const AiGradientOrb(size: 30),
                const SizedBox(width: 8),
              ] else if (!isUser) ...[
                const SizedBox(width: 38),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: radius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: typing
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: AiTypingIndicator(color: textColor),
                            )
                          : (isUser
                              ? Text(
                                  text,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                    height: 1.4,
                                  ),
                                )
                              : (streaming
                                  ? AiStreamingText(
                                      text: text,
                                      color: textColor,
                                      onCompleted: onStreamComplete,
                                    )
                                  : AiMarkdownText(
                                      data: text,
                                      color: textColor,
                                    ))),
                    ),
                    if (timestamp != null && !typing)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                        child: Text(
                          _formatTime(timestamp!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}
