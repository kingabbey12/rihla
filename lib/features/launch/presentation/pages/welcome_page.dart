import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/constants/app_constants.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/launch/presentation/providers/launch_providers.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/ui/rihla_dark_hero_background.dart';
import 'package:rihla/shared/widgets/language_selector.dart';
import 'package:rihla/shared/widgets/premium_buttons.dart';
import 'package:rihla/shared/widgets/rihla_logo.dart';
import 'package:rihla/theme/app_colors.dart';

/// Welcome screen matching the reference dark hero onboarding style.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

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
                  variant: RihlaLogoVariant.full,
                  iconSize: 72,
                  wordmarkHeight: 28,
                  color: AppColors.textPrimaryDark,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.welcomeHeadline,
                  style: context.textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.welcomeSubtitle,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryDark,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),
                PremiumPrimaryButton(
                  label: l10n.getStarted,
                  gold: true,
                  onPressed: () => context.go(RoutePaths.onboarding),
                ),
                const SizedBox(height: 12),
                PremiumSecondaryButton(
                  label: l10n.signIn,
                  onDark: true,
                  onPressed: () => context.go(RoutePaths.authentication),
                ),
                const Spacer(),
                const LanguageSelector(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
