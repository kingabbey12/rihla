import 'package:flutter/material.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Home / Work / Favorites shortcut pill from the reference dashboard.
///
/// Adds a subtle press-scale animation for premium tap feedback.
class RihlaShortcutChip extends StatefulWidget {
  const RihlaShortcutChip({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  State<RihlaShortcutChip> createState() => _RihlaShortcutChipState();
}

class _RihlaShortcutChipState extends State<RihlaShortcutChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: _pressed ? 0.95 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(RihlaReferenceTokens.pillRadius),
        elevation: 0,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(RihlaReferenceTokens.pillRadius),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(RihlaReferenceTokens.pillRadius),
              boxShadow: RihlaReferenceTokens.floatingShadow(opacity: 0.10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.highlighted
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
