import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Privacy policy and terms of service footer links.
class AuthLegalFooter extends StatelessWidget {
  const AuthLegalFooter({
    super.key,
    required this.onPrivacyPressed,
    required this.onTermsPressed,
  });

  final VoidCallback onPrivacyPressed;
  final VoidCallback onTermsPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final linkStyle = context.textTheme.bodySmall?.copyWith(
      color: context.colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return Text.rich(
      TextSpan(
        text: '${l10n.authLegalPrefix} ',
        style: context.textTheme.bodySmall,
        children: [
          TextSpan(
            text: l10n.privacyPolicy,
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onPrivacyPressed,
          ),
          TextSpan(text: ' ${l10n.authLegalAnd} '),
          TextSpan(
            text: l10n.termsOfService,
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onTermsPressed,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
