import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Celebration card shown above the journey review when the driver arrives.
class ArrivalCelebrationCard extends StatefulWidget {
  const ArrivalCelebrationCard({required this.session, super.key});

  final NavigationSession session;

  @override
  State<ArrivalCelebrationCard> createState() => _ArrivalCelebrationCardState();
}

class _ArrivalCelebrationCardState extends State<ArrivalCelebrationCard>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _confetti;
  late final List<_Confetto> _confettiPieces = _buildConfetti();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confetti.dispose();
    super.dispose();
  }

  static List<_Confetto> _buildConfetti() {
    final rng = math.Random(7);
    const colors = [
      Color(0xFF0D6E6E),
      Color(0xFF22D3EE),
      Color(0xFFE8A838),
      Color(0xFF2563EB),
      Color(0xFF22C55E),
    ];
    return List.generate(28, (i) {
      return _Confetto(
        x: rng.nextDouble(),
        delay: rng.nextDouble() * 0.25,
        drift: (rng.nextDouble() - 0.5) * 0.4,
        rotations: 1 + rng.nextDouble() * 3,
        size: 6 + rng.nextDouble() * 6,
        color: colors[i % colors.length],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teal = RihlaReferenceTokens.mapTeal;
    final session = widget.session;
    final tripMinutes =
        DateTime.now().difference(session.startedAt).inMinutes.clamp(0, 1 << 30);
    final journeyScore = session.route.journeyScore.round();
    final safetyScore =
        session.safety.assessment.overallSafetyScore.round();

    return Stack(
      children: [
        // Subtle confetti burst from the top while the card settles in.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (context, _) => CustomPaint(
                painter: _ConfettiPainter(
                  progress: _confetti.value,
                  pieces: _confettiPieces,
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 16,
              16,
              0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutBack,
            ),
            child: FadeTransition(
              opacity: _controller,
              child: Material(
                elevation: 14,
                borderRadius: BorderRadius.circular(26),
                shadowColor: teal.withValues(alpha: 0.4),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulseFlag(controller: _controller, color: teal),
                      const SizedBox(height: 14),
                      Text(
                        context.l10n.navArrivedTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.navArrivedSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.route_rounded,
                              value: session.route.distanceKm
                                  .toStringAsFixed(1),
                              unit: 'km',
                              label: context.l10n.navDistanceLeft,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.timer_outlined,
                              value: '$tripMinutes',
                              unit: 'min',
                              label: context.l10n.navTimeLeft,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ScoreTile(
                              label: context.l10n.journeyScore,
                              score: journeyScore,
                              color: teal,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ScoreTile(
                              label: context.l10n.journeySafetyScore,
                              score: safetyScore,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
        ),
      ],
    );
  }
}

/// A single falling confetto.
class _Confetto {
  const _Confetto({
    required this.x,
    required this.delay,
    required this.drift,
    required this.rotations,
    required this.size,
    required this.color,
  });

  /// Horizontal start position as a fraction of width (0–1).
  final double x;

  /// Fraction of the animation to wait before this piece starts falling.
  final double delay;

  /// Horizontal drift as a fraction of width over the fall.
  final double drift;
  final double rotations;
  final double size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.pieces});

  final double progress;
  final List<_Confetto> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final local = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final fade = local < 0.85 ? 1.0 : (1 - (local - 0.85) / 0.15);
      final dx = (p.x + p.drift * local) * size.width;
      final dy = local * (size.height * 0.9);
      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotations * local * 2 * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PulseFlag extends StatelessWidget {
  const _PulseFlag({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final t = controller.value;
              return Container(
                width: 56 + 20 * t,
                height: 56 + 20 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.18 * (1 - t)),
                ),
              );
            },
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (context, value, _) => Text(
              value.round().toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
