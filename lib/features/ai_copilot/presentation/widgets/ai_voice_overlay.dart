import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Presentation-only voice interaction phases.
enum AiVoicePhase { listening, thinking, speaking }

/// Full-screen premium voice experience: glowing mic, animated waveform, and
/// phase-specific copy. No backend voice changes — visuals only.
class AiVoiceOverlay extends StatefulWidget {
  const AiVoiceOverlay({
    required this.phase,
    required this.onClose,
    super.key,
    this.transcript,
  });

  final AiVoicePhase phase;
  final VoidCallback onClose;
  final String? transcript;

  @override
  State<AiVoiceOverlay> createState() => _AiVoiceOverlayState();
}

class _AiVoiceOverlayState extends State<AiVoiceOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const teal = RihlaReferenceTokens.mapTeal;
    const violet = Color(0xFF7C5CFF);

    final (title, subtitle) = switch (widget.phase) {
      AiVoicePhase.listening => ('Listening…', 'Speak now, I\'m all ears'),
      AiVoicePhase.thinking => ('Thinking…', 'Working on your request'),
      AiVoicePhase.speaking => ('Speaking', 'Here\'s what I found'),
    };

    return Positioned.fill(
      child: ColoredBox(
        color: theme.colorScheme.scrim.withValues(alpha: 0.7),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IconButton.filledTonal(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final pulse = widget.phase == AiVoicePhase.listening
                      ? 1 + 0.08 * math.sin(_controller.value * 2 * math.pi)
                      : 1.0;
                  return Transform.scale(
                    scale: pulse,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow rings.
                        for (var i = 0; i < 3; i++)
                          Container(
                            width: 140 + i * 46.0,
                            height: 140 + i * 46.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: teal.withValues(
                                alpha: 0.10 - i * 0.03,
                              ),
                            ),
                          ),
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [teal, violet],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: violet.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            switch (widget.phase) {
                              AiVoicePhase.listening => Icons.mic_rounded,
                              AiVoicePhase.thinking => Icons.auto_awesome_rounded,
                              AiVoicePhase.speaking => Icons.graphic_eq_rounded,
                            },
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    size: const Size(260, 56),
                    painter: _WaveformPainter(
                      progress: _controller.value,
                      active: widget.phase != AiVoicePhase.thinking,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.transcript ?? subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.progress,
    required this.active,
    required this.color,
  });

  final double progress;
  final bool active;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const bars = 28;
    final gap = size.width / bars;
    for (var i = 0; i < bars; i++) {
      final phase = progress * 2 * math.pi + i * 0.5;
      final amp = active ? (0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase))) : 0.18;
      final h = size.height * amp;
      final x = gap * i + gap / 2;
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.progress != progress || old.active != active;
}
