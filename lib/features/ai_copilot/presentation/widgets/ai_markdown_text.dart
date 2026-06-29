import 'package:flutter/material.dart';

/// Lightweight markdown renderer for AI replies.
///
/// Supports a pragmatic subset — headings (`#`/`##`), bullet lists (`- `/`* `),
/// fenced code blocks (```), inline code (`` ` ``) and bold (`**`). Deliberately
/// dependency-free so the AI surface stays self-contained.
class AiMarkdownText extends StatelessWidget {
  const AiMarkdownText({
    required this.data,
    super.key,
    this.color,
    this.baseStyle,
  });

  final String data;
  final Color? color;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = (baseStyle ?? theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(height: 1.45, color: color);

    final blocks = <Widget>[];
    final lines = data.split('\n');
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // Fenced code block.
      if (trimmed.startsWith('```')) {
        final buffer = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          buffer.add(lines[i]);
          i++;
        }
        i++; // consume closing fence
        blocks.add(_CodeBlock(code: buffer.join('\n')));
        continue;
      }

      if (trimmed.isEmpty) {
        blocks.add(const SizedBox(height: 8));
        i++;
        continue;
      }

      // Headings.
      if (trimmed.startsWith('## ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: _inline(trimmed.substring(3),
              base.copyWith(fontWeight: FontWeight.w800, fontSize: (base.fontSize ?? 14) + 1)),
        ));
        i++;
        continue;
      }
      if (trimmed.startsWith('# ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: _inline(trimmed.substring(2),
              base.copyWith(fontWeight: FontWeight.w800, fontSize: (base.fontSize ?? 14) + 3)),
        ));
        i++;
        continue;
      }

      // Bullets.
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Icon(Icons.circle, size: 6, color: base.color),
              ),
              Expanded(child: _inline(trimmed.substring(2), base)),
            ],
          ),
        ));
        i++;
        continue;
      }

      blocks.add(Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: _inline(trimmed, base),
      ));
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  /// Parses bold (`**`) and inline code (`` ` ``) into a rich [Text].
  Widget _inline(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'(\*\*(.+?)\*\*)|(`(.+?)`)');
    var last = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: style.color?.withValues(alpha: 0.12),
          ),
        ));
      }
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.4,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
