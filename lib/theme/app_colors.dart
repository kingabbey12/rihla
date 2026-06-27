import 'package:flutter/material.dart';

/// Rihla brand color palette.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF0D6E6E);
  static const Color primaryLight = Color(0xFF14A3A3);
  static const Color primaryDark = Color(0xFF094949);
  static const Color secondary = Color(0xFFE8A838);
  static const Color secondaryLight = Color(0xFFF5C76B);

  // Neutrals — Light
  static const Color backgroundLight = Color(0xFFF8FAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color errorLight = Color(0xFFDC2626);

  // Neutrals — Dark
  static const Color backgroundDark = Color(0xFF0F1419);
  static const Color surfaceDark = Color(0xFF1A2332);
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color borderDark = Color(0xFF374151);
  static const Color errorDark = Color(0xFFF87171);
}
