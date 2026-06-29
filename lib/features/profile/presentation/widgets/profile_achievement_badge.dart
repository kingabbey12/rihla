import 'package:flutter/material.dart';
import 'package:rihla/features/profile/presentation/data/profile_showcase_data.dart';

/// Animated achievement badge — unlocked badges glow with their gradient,
/// locked badges show a desaturated ring with progress.
class ProfileAchievementBadge extends StatelessWidget {
  const ProfileAchievementBadge({
    required this.achievement,
    required this.index,
    super.key,
  });

  final ProfileAchievement achievement;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = achievement.unlocked;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 90),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(
        scale: 0.85 + 0.15 * t.clamp(0.0, 1.0),
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!unlocked)
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: achievement.progress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (context, v, _) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 4,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor:
                            AlwaysStoppedAnimation(achievement.gradient.last),
                      ),
                    ),
                  ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: unlocked
                        ? LinearGradient(
                            colors: achievement.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: unlocked
                        ? null
                        : theme.colorScheme.surfaceContainerHighest,
                    boxShadow: unlocked
                        ? [
                            BoxShadow(
                              color: achievement.gradient.last
                                  .withValues(alpha: 0.45),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    unlocked ? achievement.icon : Icons.lock_outline_rounded,
                    color: unlocked
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            achievement.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
