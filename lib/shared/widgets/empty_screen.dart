import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/shared/design/rihla_design.dart';

/// Premium empty state for lists and content areas with no data: a gradient
/// illustration badge, friendly copy, and primary / secondary calls to action.
class EmptyScreen extends StatelessWidget {
  const EmptyScreen({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.gradient,
  });

  final String? title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final displayTitle = title ?? context.l10n.emptyTitle;
    final displayMessage = message ?? context.l10n.emptyMessage;

    return Center(
      child: RihlaContentWidth(
        maxWidth: 420,
        child: Padding(
          padding: const EdgeInsets.all(RihlaSpacing.xxl),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: RihlaMotion.slow,
            curve: RihlaMotion.standard,
            builder: (context, t, child) =>
                RihlaMotion.entrance(t, rise: 18, child: child!),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradient ?? RihlaGradients.brand,
                    boxShadow: RihlaShadows.hero(
                      glow: context.colorScheme.primary,
                    ),
                  ),
                  child: Icon(icon, size: 48, color: Colors.white),
                ),
                const SizedBox(height: RihlaSpacing.xxl),
                Text(
                  displayTitle,
                  style: context.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: RihlaSpacing.md),
                Text(
                  displayMessage,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(height: RihlaSpacing.xxl),
                  FilledButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
                if (onSecondaryAction != null &&
                    secondaryActionLabel != null) ...[
                  const SizedBox(height: RihlaSpacing.sm),
                  TextButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryActionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
