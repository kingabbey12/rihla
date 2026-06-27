import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/constants/launch_constants.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/widgets/rihla_logo.dart';
import 'package:rihla/theme/app_colors.dart';

/// Premium animated brand splash with fade-in logo and tagline.
class BrandSplashPage extends StatefulWidget {
  const BrandSplashPage({super.key});

  @override
  State<BrandSplashPage> createState() => _BrandSplashPageState();
}

class _BrandSplashPageState extends State<BrandSplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _taglineController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  Timer? _holdTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: LaunchConstants.logoAnimationDuration,
    );
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );
    _taglineOpacity = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOutCubic),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _logoController.forward();
    if (!mounted) return;
    await _taglineController.forward();
    if (!mounted) return;
    _holdTimer = Timer(LaunchConstants.brandSplashHoldDuration, _goToWelcome);
  }

  void _goToWelcome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(RoutePaths.welcome);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _logoController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _logoOpacity,
              child: const RihlaLogo(
                variant: RihlaLogoVariant.full,
                iconSize: 88,
                wordmarkHeight: 32,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _taglineOpacity,
              child: SlideTransition(
                position: _taglineSlide,
                child: Text(
                  context.l10n.brandTagline,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondaryDark,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
