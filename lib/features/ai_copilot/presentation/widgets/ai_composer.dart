import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rihla/shared/design/rihla_design.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Glass composer bar: text field, mic (voice), and an animated send button.
class AiComposer extends StatefulWidget {
  const AiComposer({
    required this.onSend,
    required this.onMic,
    super.key,
    this.enabled = true,
    this.hintText = 'Ask anything…',
  });

  final ValueChanged<String> onSend;
  final VoidCallback onMic;
  final bool enabled;
  final String hintText;

  @override
  State<AiComposer> createState() => _AiComposerState();
}

class _AiComposerState extends State<AiComposer> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    RihlaHaptics.success();
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const teal = RihlaReferenceTokens.mapTeal;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: RihlaGlass.blurSigma,
              sigmaY: RihlaGlass.blurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface
                    .withValues(alpha: isDark ? 0.7 : 0.82),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                boxShadow: RihlaReferenceTokens.floatingShadow(opacity: 0.12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.enabled ? widget.onMic : null,
                    icon: const Icon(Icons.mic_rounded),
                    color: teal,
                    tooltip: 'Voice',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: widget.enabled,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedScale(
                    scale: _hasText ? 1 : 0.85,
                    duration: RihlaMotion.fast,
                    curve: RihlaMotion.emphasized,
                    child: Material(
                      color: _hasText
                          ? teal
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _hasText ? _send : null,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 22,
                            color: _hasText
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
