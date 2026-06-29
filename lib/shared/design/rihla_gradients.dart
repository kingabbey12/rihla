import 'package:flutter/widgets.dart';
import 'package:rihla/theme/app_colors.dart';

/// Gradient presets shared across the product so accent surfaces (AI orb,
/// brand banners, score badges) all draw from the same palette.
abstract final class RihlaGradients {
  /// AI identity gradient — teal into violet.
  static const LinearGradient ai = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF31C5C7), Color(0xFF7C5CFF)],
  );

  /// Primary brand gradient.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primaryDark],
  );

  /// Gold / reward gradient for achievements and membership.
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondaryLight, AppColors.secondary],
  );

  /// Calm dark hero backdrop used behind premium headers.
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF13313A), Color(0xFF0F1419)],
  );

  /// Subtle neutral gradient for skeleton placeholders (shimmer base).
  static LinearGradient shimmer(Color base, Color highlight, double t) {
    return LinearGradient(
      begin: Alignment(-1 - 2 * (1 - t), 0),
      end: Alignment(1 + 2 * t, 0),
      colors: [base, highlight, base],
      stops: const [0.35, 0.5, 0.65],
    );
  }
}
