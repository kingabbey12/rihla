import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/constants/app_constants.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/launch/presentation/providers/launch_providers.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/widgets/language_selector.dart';
import 'package:rihla/shared/widgets/premium_buttons.dart';
import 'package:rihla/shared/widgets/rihla_logo.dart';
import 'package:rihla/shared/widgets/theme_mode_toggle.dart';

/// Welcome screen with language, theme, and entry actions.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

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
                iconSize: 80,
              ),
              const SizedBox(height: 40),
              Text(
                l10n.welcomeHeadline,
                style: context.textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.welcomeSubtitle,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              PremiumPrimaryButton(
                label: l10n.getStarted,
                onPressed: () => context.go(RoutePaths.onboarding),
              ),
              const SizedBox(height: 12),
              PremiumSecondaryButton(
                label: l10n.signIn,
                onPressed: () => context.go(RoutePaths.authentication),
              ),
              const SizedBox(height: 12),
              PremiumTextButton(
                label: l10n.continueAsGuest,
                onPressed: () async {
                  await ref
                      .read(onboardingCompletionProvider.notifier)
                      .markCompleted();
                  if (context.mounted) {
                    context.go(RoutePaths.permissions);
                  }
                },
              ),
              const Spacer(),
              const LanguageSelector(),
              const SizedBox(height: 16),
              const ThemeModeToggle(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
