import 'package:flutter/material.dart';

/// Animated integer counter that eases up from zero on first build.
class ProfileCounter extends StatelessWidget {
  const ProfileCounter({
    required this.value,
    required this.style,
    super.key,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1100),
  });

  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '$prefix${v.round()}$suffix',
        style: style,
      ),
    );
  }
}
