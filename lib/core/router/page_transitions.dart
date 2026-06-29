import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/shared/design/rihla_motion.dart';

/// Premium fade + slide page transition for first-launch routes.
CustomTransitionPage<T> fadeSlidePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: RihlaMotion.page,
    reverseTransitionDuration: RihlaMotion.page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: RihlaMotion.standard,
        reverseCurve: RihlaMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}
