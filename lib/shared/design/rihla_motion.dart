import 'package:flutter/material.dart';

/// Shared motion system — one source of truth for durations and curves so
/// every animation across Rihla feels consistent.
abstract final class RihlaMotion {
  // —— Durations ——
  /// Micro-interactions: presses, toggles, chips.
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transitions: cards, switches, fades.
  static const Duration medium = Duration(milliseconds: 250);

  /// Expressive transitions: sheets, expansions, hero content.
  static const Duration slow = Duration(milliseconds: 400);

  /// Route/page transitions.
  static const Duration page = Duration(milliseconds: 450);

  // —— Curves ——
  /// Default easing for entrances and most transitions.
  static const Curve standard = Curves.easeOutCubic;

  /// Easing for exits / reverse transitions.
  static const Curve exit = Curves.easeInCubic;

  /// Playful overshoot for badges, FABs, confirmations.
  static const Curve emphasized = Curves.easeOutBack;

  /// A reusable fade + rise + scale entrance, used by cards and list items.
  static Widget entrance(
    double t, {
    required Widget child,
    double rise = 14,
    double fromScale = 0.97,
    Offset slide = Offset.zero,
  }) {
    final clamped = t.clamp(0.0, 1.0);
    return Opacity(
      opacity: clamped,
      child: Transform.translate(
        offset: Offset(slide.dx * (1 - clamped), rise * (1 - clamped) + slide.dy * (1 - clamped)),
        child: Transform.scale(
          scale: fromScale + (1 - fromScale) * clamped,
          child: child,
        ),
      ),
    );
  }
}
