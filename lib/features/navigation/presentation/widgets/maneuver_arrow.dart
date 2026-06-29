import 'package:flutter/material.dart';
import 'package:rihla/features/navigation/domain/entities/maneuver_type.dart';
import 'package:rihla/features/navigation/presentation/extensions/maneuver_type_icons.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Large maneuver arrow with an animated progress ring that fills as the driver
/// approaches the turn. The icon cross-fades + scales when the maneuver changes.
class ManeuverArrow extends StatelessWidget {
  const ManeuverArrow({
    required this.type,
    required this.progress,
    super.key,
    this.size = 64,
  });

  final ManeuverType type;

  /// 0..1 approach progress (1 = at the maneuver).
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final teal = RihlaReferenceTokens.mapTeal;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0, 1)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, _) => SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                backgroundColor: teal.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(teal),
              ),
            ),
          ),
          Container(
            width: size - 16,
            height: size - 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [teal, teal.withValues(alpha: 0.72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                type.icon,
                key: ValueKey(type),
                color: Colors.white,
                size: size * 0.42,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
