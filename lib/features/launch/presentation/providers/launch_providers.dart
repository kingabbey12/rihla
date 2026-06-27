import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/launch/data/onboarding_pages_registry.dart';
import 'package:rihla/features/launch/domain/models/onboarding_page_model.dart';

/// Provides the list of onboarding pages from the registry.
final onboardingPagesProvider = Provider<List<OnboardingPageModel>>(
  (ref) => OnboardingPagesRegistry.pages,
);

/// Manages onboarding completion state with persistence.
final onboardingCompletionProvider =
    NotifierProvider<OnboardingCompletionNotifier, bool>(
  OnboardingCompletionNotifier.new,
);

class OnboardingCompletionNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(appPreferencesRepositoryProvider).onboardingCompleted;
  }

  Future<void> markCompleted() async {
    state = true;
    await ref.read(appPreferencesRepositoryProvider).setOnboardingCompleted(
          true,
        );
  }
}

/// Marks the full launch flow as complete (skip on future app opens).
final launchFlowCompletionProvider =
    NotifierProvider<LaunchFlowCompletionNotifier, bool>(
  LaunchFlowCompletionNotifier.new,
);

class LaunchFlowCompletionNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(appPreferencesRepositoryProvider).launchFlowCompleted;
  }

  Future<void> markCompleted() async {
    state = true;
    await ref.read(appPreferencesRepositoryProvider).setLaunchFlowCompleted(
          true,
        );
  }
}
