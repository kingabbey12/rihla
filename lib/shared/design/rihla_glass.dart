import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rihla/shared/design/rihla_elevation.dart';
import 'package:rihla/shared/design/rihla_radii.dart';

/// Glass / frosted-surface specification. Every floating translucent surface
/// (search bars, AI panels, dialogs, sheets) should be built from
/// [RihlaGlassSurface] so blur, opacity and borders stay identical.
abstract final class RihlaGlass {
  static const double blurSigma = 18;

  static double surfaceOpacity(Brightness b) =>
      b == Brightness.dark ? 0.55 : 0.72;

  static double borderOpacity(Brightness b) =>
      b == Brightness.dark ? 0.16 : 0.55;

  static Color surfaceColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.surface.withValues(alpha: surfaceOpacity(scheme.brightness));
  }

  static Color borderColor(BuildContext context) {
    final b = Theme.of(context).colorScheme.brightness;
    final base = b == Brightness.dark ? Colors.white : Colors.white;
    return base.withValues(alpha: borderOpacity(b));
  }
}

/// A frosted glass surface that applies the shared blur, translucent fill,
/// hairline border, radius and floating shadow.
class RihlaGlassSurface extends StatelessWidget {
  const RihlaGlassSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = RihlaRadii.xlAll,
    this.onTap,
    this.blur = true,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool blur;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: RihlaGlass.surfaceColor(context),
        borderRadius: borderRadius,
        border: Border.all(color: RihlaGlass.borderColor(context), width: 1),
        boxShadow: shadow ? RihlaShadows.floating() : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    Widget surface = ClipRRect(
      borderRadius: borderRadius,
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: RihlaGlass.blurSigma,
                sigmaY: RihlaGlass.blurSigma,
              ),
              child: content,
            )
          : content,
    );

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: surface,
        ),
      );
    }
    return surface;
  }
}
