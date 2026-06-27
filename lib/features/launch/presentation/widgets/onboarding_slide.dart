import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rihla/core/constants/app_constants.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/launch/domain/models/onboarding_button_config.dart';
import 'package:rihla/features/launch/domain/models/onboarding_page_model.dart';
import 'package:rihla/features/launch/presentation/extensions/onboarding_page_model_l10n.dart';
import 'package:rihla/shared/widgets/premium_buttons.dart';

/// Renders a single onboarding page from an [OnboardingPageModel].
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    super.key,
    required this.model,
    required this.onPrimaryPressed,
    this.onSecondaryPressed,
  });

  final OnboardingPageModel model;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding * 1.5,
      ),
      child: Column(
        children: [
          const Spacer(flex: 1),
          SvgPicture.asset(
            model.illustrationAsset,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 48),
          Text(
            model.title(l10n),
            style: context.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            model.subtitle(l10n),
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
          PremiumPrimaryButton(
            label: model.buttonLabel(l10n, model.primaryButton),
            onPressed: onPrimaryPressed,
          ),
          if (model.secondaryButton != null && onSecondaryPressed != null) ...[
            const SizedBox(height: 12),
            PremiumSecondaryButton(
              label: model.buttonLabel(l10n, model.secondaryButton!),
              onPressed: onSecondaryPressed!,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Handles button actions defined in [OnboardingButtonConfig].
void handleOnboardingAction({
  required OnboardingButtonAction action,
  required PageController pageController,
  required int pageCount,
  required VoidCallback onFinish,
}) {
  switch (action) {
    case OnboardingButtonAction.next:
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    case OnboardingButtonAction.skip:
    case OnboardingButtonAction.finish:
      onFinish();
  }
}
