import 'package:flutter/material.dart';
import 'package:rihla/core/constants/app_constants.dart';

/// Styled button for social authentication providers.
class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isApple = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isApple;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
