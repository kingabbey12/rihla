import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/constants/app_constants.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/account/presentation/providers/account_providers.dart';
import 'package:rihla/features/account/presentation/widgets/email_auth_sheet.dart';
import 'package:rihla/features/authentication/presentation/widgets/auth_legal_footer.dart';
import 'package:rihla/features/authentication/presentation/widgets/auth_social_button.dart';
import 'package:rihla/features/launch/presentation/providers/launch_providers.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/ui/rihla_dark_hero_background.dart';
import 'package:rihla/shared/widgets/premium_buttons.dart';
import 'package:rihla/shared/widgets/rihla_logo.dart';
import 'package:rihla/theme/app_colors.dart';

/// Authentication entry screen wired to [AccountController].
class AuthEntryPage extends ConsumerWidget {
  const AuthEntryPage({super.key});

  Future<void> _completeAndEnterApp(BuildContext context, WidgetRef ref) async {
    await ref.read(launchFlowCompletionProvider.notifier).markCompleted();
    // Enter the production map experience (AI Home Dashboard + Maps).
    if (context.mounted) context.go(RoutePaths.maps);
  }

  void _showEmailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EmailAuthSheet(
        onSuccess: () => _completeAndEnterApp(context, ref),
      ),
    );
  }

  Future<void> _socialSignIn(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() signIn,
  ) async {
    await signIn();
    await _completeAndEnterApp(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(accountControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: RihlaDarkHeroBackground(
        child: SafeArea(
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
                  color: AppColors.textPrimaryDark,
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.authEntryTitle,
                  style: context.textTheme.headlineLarge?.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.authEntrySubtitle,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),
                PremiumPrimaryButton(
                  label: l10n.continueWithEmail,
                  gold: true,
                  onPressed: () => _showEmailSheet(context, ref),
                ),
              const SizedBox(height: 12),
              AuthSocialButton(
                label: l10n.continueWithGoogle,
                onPressed: () => _socialSignIn(
                  context,
                  ref,
                  controller.signInWithGoogle,
                ),
              ),
              const SizedBox(height: 12),
              AuthSocialButton(
                label: l10n.continueWithApple,
                onPressed: () => _socialSignIn(
                  context,
                  ref,
                  controller.signInWithApple,
                ),
                isApple: true,
              ),
              const SizedBox(height: 12),
              PremiumTextButton(
                label: l10n.continueAsGuest,
                onPressed: () async {
                  await controller.continueAsGuest();
                  await _completeAndEnterApp(context, ref);
                },
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
      ),
    );
  }
}
