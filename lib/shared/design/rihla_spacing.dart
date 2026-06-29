import 'package:flutter/widgets.dart';

/// 8-point spacing system. All layout gaps should come from these tokens.
abstract final class RihlaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Maximum readable content width on tablet / desktop. Content wider than
  /// this is centered with side gutters to avoid stretched phone layouts.
  static const double maxContentWidth = 640;

  /// Wider cap for dashboards and multi-column layouts.
  static const double maxWideContentWidth = 960;

  /// Breakpoints.
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 900;

  /// Horizontal page padding that grows on larger screens.
  static double horizontalPadding(double width) {
    if (width >= desktopBreakpoint) return xxxl;
    if (width >= tabletBreakpoint) return xxl;
    return lg;
  }
}

/// Centers and width-limits its child so phone layouts don't stretch on
/// tablet/desktop. Drop-in wrapper for page bodies.
class RihlaContentWidth extends StatelessWidget {
  const RihlaContentWidth({
    required this.child,
    super.key,
    this.maxWidth = RihlaSpacing.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
