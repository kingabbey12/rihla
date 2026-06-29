import 'package:flutter/material.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Reference-style floating surface card for map overlays and sheets.
class RihlaFloatingCard extends StatelessWidget {
  const RihlaFloatingCard({
    required this.child,
    super.key,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius = RihlaReferenceTokens.cardRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final surface = color ?? Theme.of(context).colorScheme.surface;
    final card = Material(
      color: surface,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: RihlaReferenceTokens.floatingShadow(),
        ),
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: card,
    );
  }
}
