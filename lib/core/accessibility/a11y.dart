import 'package:flutter/material.dart';

/// Accessibility constants and helpers shared across the app.
abstract final class A11y {
  /// Minimum touch target per Material / WCAG 2.5.5 (48dp).
  static const double minTouchTarget = 48.0;

  /// Clamp bounds for user/OS text scaling so fixed-height overlays survive
  /// large accessibility font sizes without clipping.
  static const double minTextScale = 0.85;
  static const double maxTextScale = 1.6;

  /// Returns a [TextScaler] clamped to safe bounds for the given context.
  static TextScaler clampedTextScaler(BuildContext context) {
    return MediaQuery.textScalerOf(context)
        .clamp(minScaleFactor: minTextScale, maxScaleFactor: maxTextScale);
  }
}

/// Wraps [child] so its hit area is at least [A11y.minTouchTarget] in both axes.
class MinTouchTarget extends StatelessWidget {
  const MinTouchTarget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: A11y.minTouchTarget,
        minHeight: A11y.minTouchTarget,
      ),
      child: Center(child: child),
    );
  }
}

/// Semantics-annotated icon button that guarantees a label and touch target.
class AccessibleIconButton extends StatelessWidget {
  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: IconButton(
        icon: Icon(icon, color: color),
        tooltip: tooltip ?? label,
        onPressed: onPressed,
        constraints: const BoxConstraints(
          minWidth: A11y.minTouchTarget,
          minHeight: A11y.minTouchTarget,
        ),
      ),
    );
  }
}
