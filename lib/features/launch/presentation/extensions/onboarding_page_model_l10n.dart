import 'package:rihla/features/launch/domain/models/onboarding_button_config.dart';
import 'package:rihla/features/launch/domain/models/onboarding_page_model.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

/// Resolves localized strings for [OnboardingPageModel].
extension OnboardingPageModelL10n on OnboardingPageModel {
  String title(AppLocalizations l10n) => switch (id) {
        'ai_navigation' => l10n.onboardingAiNavigationTitle,
        'offline_maps' => l10n.onboardingOfflineMapsTitle,
        'road_safety' => l10n.onboardingRoadSafetyTitle,
        'emergency' => l10n.onboardingEmergencyTitle,
        _ => id,
      };

  String subtitle(AppLocalizations l10n) => switch (id) {
        'ai_navigation' => l10n.onboardingAiNavigationSubtitle,
        'offline_maps' => l10n.onboardingOfflineMapsSubtitle,
        'road_safety' => l10n.onboardingRoadSafetySubtitle,
        'emergency' => l10n.onboardingEmergencySubtitle,
        _ => '',
      };

  String buttonLabel(
    AppLocalizations l10n,
    OnboardingButtonConfig config,
  ) {
    if (config.labelKey != null) {
      return switch (config.labelKey) {
        'startMyJourney' => l10n.startMyJourney,
        _ => config.labelKey!,
      };
    }
    return switch (config.action) {
      OnboardingButtonAction.next => l10n.onboardingNext,
      OnboardingButtonAction.skip => l10n.onboardingSkip,
      OnboardingButtonAction.finish => l10n.startMyJourney,
    };
  }
}
