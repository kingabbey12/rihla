import 'package:rihla/core/constants/asset_paths.dart';
import 'package:rihla/features/launch/domain/models/onboarding_button_config.dart';
import 'package:rihla/features/launch/domain/models/onboarding_page_model.dart';

/// Registry of onboarding pages. Add pages here to extend onboarding.
abstract final class OnboardingPagesRegistry {
  static const List<OnboardingPageModel> pages = [
    OnboardingPageModel(
      id: 'ai_navigation',
      illustrationAsset: AssetPaths.onboardingAiNavigation,
      primaryButton: OnboardingButtonConfig(action: OnboardingButtonAction.next),
      secondaryButton: OnboardingButtonConfig(
        action: OnboardingButtonAction.skip,
        isPrimary: false,
      ),
    ),
    OnboardingPageModel(
      id: 'offline_maps',
      illustrationAsset: AssetPaths.onboardingOfflineMaps,
      primaryButton: OnboardingButtonConfig(action: OnboardingButtonAction.next),
      secondaryButton: OnboardingButtonConfig(
        action: OnboardingButtonAction.skip,
        isPrimary: false,
      ),
    ),
    OnboardingPageModel(
      id: 'road_safety',
      illustrationAsset: AssetPaths.onboardingRoadSafety,
      primaryButton: OnboardingButtonConfig(action: OnboardingButtonAction.next),
      secondaryButton: OnboardingButtonConfig(
        action: OnboardingButtonAction.skip,
        isPrimary: false,
      ),
    ),
    OnboardingPageModel(
      id: 'emergency',
      illustrationAsset: AssetPaths.onboardingEmergency,
      primaryButton: OnboardingButtonConfig(
        action: OnboardingButtonAction.finish,
        labelKey: 'startMyJourney',
      ),
    ),
  ];
}
