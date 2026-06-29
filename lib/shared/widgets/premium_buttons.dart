import 'package:flutter/material.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';
import 'package:rihla/theme/app_colors.dart';

/// Primary call-to-action button with premium styling.
class PremiumPrimaryButton extends StatelessWidget {
  const PremiumPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
    this.gold = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool expanded;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final button = gold
        ? ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: RihlaReferenceTokens.goldAccent,
              foregroundColor: AppColors.textPrimaryLight,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          )
        : ElevatedButton(
            onPressed: onPressed,
            child: Text(label),
          );
    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

/// Secondary outlined button for alternate actions.
class PremiumSecondaryButton extends StatelessWidget {
  const PremiumSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
    this.onDark = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool expanded;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final button = onDark
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(label),
          )
        : OutlinedButton(
            onPressed: onPressed,
            child: Text(label),
          );
    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

/// Text-only button for tertiary actions.
class PremiumTextButton extends StatelessWidget {
  const PremiumTextButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
