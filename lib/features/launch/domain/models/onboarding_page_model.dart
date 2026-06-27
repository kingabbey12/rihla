import 'package:rihla/features/launch/domain/models/onboarding_button_config.dart';

/// Data model for a single onboarding page.
/// Add new pages to [OnboardingPagesRegistry] without changing UI logic.
class OnboardingPageModel {
  const OnboardingPageModel({
    required this.id,
    required this.illustrationAsset,
    required this.primaryButton,
    this.secondaryButton,
  });

  final String id;
  final String illustrationAsset;
  final OnboardingButtonConfig primaryButton;
  final OnboardingButtonConfig? secondaryButton;
}
