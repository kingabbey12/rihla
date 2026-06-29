import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_markdown_text.dart';

/// Reveals [text] progressively to evoke live token streaming, then renders the
/// final result as markdown. Purely a presentation effect — no backend changes.
class AiStreamingText extends StatefulWidget {
  const AiStreamingText({
    required this.text,
    super.key,
    this.color,
    this.stream = true,
    this.onCompleted,
  });

  final String text;
  final Color? color;
  final bool stream;
  final VoidCallback? onCompleted;

  @override
  State<AiStreamingText> createState() => _AiStreamingTextState();
}

class _AiStreamingTextState extends State<AiStreamingText> {
  Timer? _timer;
  int _chars = 0;

  @override
  void initState() {
    super.initState();
    if (widget.stream) {
      _start();
    } else {
      _chars = widget.text.length;
    }
  }

  void _start() {
    const step = 3; // characters revealed per tick
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      setState(() {
        _chars = (_chars + step).clamp(0, widget.text.length);
      });
      if (_chars >= widget.text.length) {
        timer.cancel();
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AiStreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _chars = widget.stream ? 0 : widget.text.length;
      if (widget.stream) _start();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.text.substring(0, _chars);
    return AiMarkdownText(data: visible, color: widget.color);
  }
}
