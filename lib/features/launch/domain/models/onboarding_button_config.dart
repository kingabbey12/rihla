/// Defines a button action on an onboarding page.
enum OnboardingButtonAction {
  next,
  skip,
  finish,
}

/// Configuration for an onboarding page button.
class OnboardingButtonConfig {
  const OnboardingButtonConfig({
    required this.action,
    this.labelKey,
    this.isPrimary = true,
  });

  final OnboardingButtonAction action;
  final String? labelKey;
  final bool isPrimary;
}
