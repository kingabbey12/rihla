import 'package:flutter/widgets.dart';

/// Shadow presets. Floating surfaces should use these so depth reads the same
/// everywhere instead of mixing hand-tuned shadows.
abstract final class RihlaShadows {
  /// Subtle lift for resting cards and list tiles.
  static List<BoxShadow> soft({Color color = const Color(0xFF000000)}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Floating overlays: search bars, map cards, bottom sheets.
  static List<BoxShadow> floating({Color color = const Color(0xFF000000)}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// Hero emphasis: primary CTAs, active FAB, SOS.
  static List<BoxShadow> hero({required Color glow}) => [
        BoxShadow(
          color: glow.withValues(alpha: 0.35),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];
}
