import 'package:flutter/material.dart';
import 'package:rihla/theme/app_colors.dart';

/// Visual tokens aligned with the Rihla production reference.
abstract final class RihlaReferenceTokens {
  static const double cardRadius = 20;
  static const double pillRadius = 22;
  static const double navBarRadius = 24;

  static List<BoxShadow> floatingShadow({double opacity = 0.12}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static const Color goldAccent = AppColors.secondary;
  static const Color emergencyRed = Color(0xFFE53935);
  static const Color mapTeal = AppColors.primary;
  static const Color darkHero = Color(0xFF0B1118);
  static const Color darkSurface = Color(0xFF151C28);
}
