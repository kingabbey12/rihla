import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/constants/app_constants.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/authentication/presentation/widgets/auth_legal_footer.dart';
import 'package:rihla/features/authentication/presentation/widgets/auth_social_button.dart';
import 'package:rihla/features/launch/presentation/providers/launch_providers.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/widgets/premium_buttons.dart';
import 'package:rihla/shared/widgets/rihla_logo.dart';

/// Authentication entry screen — UI only, no backend integration.
class AuthEntryPage extends ConsumerWidget {
  const AuthEntryPage({super.key});

  Future<void> _completeAndGoHome(BuildContext context, WidgetRef ref) async {
    await ref.read(launchFlowCompletionProvider.notifier).markCompleted();
    if (context.mounted) context.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding * 1.5,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const RihlaLogo(
                variant: RihlaLogoVariant.iconOnly,
                iconSize: 72,
              ),
              const SizedBox(height: 32),
              Text(
                l10n.authEntryTitle,
                style: context.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.authEntrySubtitle,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              PremiumPrimaryButton(
                label: l10n.continueWithEmail,
                onPressed: () => _completeAndGoHome(context, ref),
              ),
              const SizedBox(height: 12),
              AuthSocialButton(
                label: l10n.continueWithGoogle,
                onPressed: () => _completeAndGoHome(context, ref),
              ),
              const SizedBox(height: 12),
              AuthSocialButton(
                label: l10n.continueWithApple,
                onPressed: () => _completeAndGoHome(context, ref),
                isApple: true,
              ),
              const SizedBox(height: 12),
              PremiumTextButton(
                label: l10n.continueAsGuest,
                onPressed: () => _completeAndGoHome(context, ref),
              ),
              const Spacer(),
              AuthLegalFooter(
                onPrivacyPressed: () {},
                onTermsPressed: () {},
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
