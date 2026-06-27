/// Timing constants for the first-launch experience.
abstract final class LaunchConstants {
  static const Duration nativeSplashDuration = Duration(seconds: 2);
  static const Duration brandSplashAnimationDuration = Duration(
    milliseconds: 1800,
  );
  static const Duration brandSplashHoldDuration = Duration(milliseconds: 800);
  static const Duration pageTransitionDuration = Duration(milliseconds: 450);
  static const Duration logoAnimationDuration = Duration(milliseconds: 1200);
}
