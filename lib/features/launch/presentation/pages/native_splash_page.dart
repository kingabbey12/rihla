import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/constants/launch_constants.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/widgets/rihla_logo.dart';
import 'package:rihla/theme/app_colors.dart';

/// Native-style splash with logo and loading animation (~2 seconds).
class NativeSplashPage extends StatefulWidget {
  const NativeSplashPage({super.key});

  @override
  State<NativeSplashPage> createState() => _NativeSplashPageState();
}

class _NativeSplashPageState extends State<NativeSplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _navigationTimer = Timer(LaunchConstants.nativeSplashDuration, () {
      if (mounted) context.go(RoutePaths.brandSplash);
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _pulseController.dispose();
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
            const RihlaLogo(
              variant: RihlaLogoVariant.iconOnly,
              iconSize: 96,
            ),
            const SizedBox(height: 48),
            FadeTransition(
              opacity: Tween<double>(begin: 0.4, end: 1).animate(
                CurvedAnimation(
                  parent: _pulseController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
