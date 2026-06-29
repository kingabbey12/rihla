import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Animated gradient "AI orb" used as the copilot avatar across surfaces.
///
/// Gently rotates a multi-stop gradient and breathes a soft glow, giving the
/// assistant a living, premium presence.
class AiGradientOrb extends StatefulWidget {
  const AiGradientOrb({
    super.key,
    this.size = 48,
    this.icon = Icons.auto_awesome_rounded,
    this.animate = true,
  });

  final double size;
  final IconData icon;
  final bool animate;

  @override
  State<AiGradientOrb> createState() => _AiGradientOrbState();
}

class _AiGradientOrbState extends State<AiGradientOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const teal = RihlaReferenceTokens.mapTeal;
    const violet = Color(0xFF7C5CFF);
    const cyan = Color(0xFF31C5C7);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * 2 * math.pi;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              transform: GradientRotation(angle),
              colors: const [teal, cyan, violet, teal],
            ),
            boxShadow: [
              BoxShadow(
                color: violet.withValues(alpha: 0.35),
                blurRadius: widget.size * 0.4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Center(
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: widget.size * 0.46,
        ),
      ),
    );
  }
}
