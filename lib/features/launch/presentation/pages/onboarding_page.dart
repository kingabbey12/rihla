import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/features/launch/presentation/providers/launch_providers.dart';
import 'package:rihla/features/launch/presentation/widgets/onboarding_slide.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/widgets/onboarding_page_indicator.dart';

/// Swipeable onboarding flow driven by [OnboardingPageModel] list.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingCompletionProvider.notifier).markCompleted();
    if (mounted) context.go(RoutePaths.permissions);
  }

  void _onPrimary(int index, pages) {
    final model = pages[index];
    handleOnboardingAction(
      action: model.primaryButton.action,
      pageController: _pageController,
      pageCount: pages.length,
      onFinish: _finishOnboarding,
    );
  }

  void _onSecondary(int index, pages) {
    final secondary = pages[index].secondaryButton;
    if (secondary == null) return;
    handleOnboardingAction(
      action: secondary.action,
      pageController: _pageController,
      pageCount: pages.length,
      onFinish: _finishOnboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(onboardingPagesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => OnboardingSlide(
                  model: pages[index],
                  onPrimaryPressed: () => _onPrimary(index, pages),
                  onSecondaryPressed: pages[index].secondaryButton != null
                      ? () => _onSecondary(index, pages)
                      : null,
                ),
              ),
            ),
            OnboardingPageIndicator(
              pageCount: pages.length,
              currentPage: _currentPage,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
