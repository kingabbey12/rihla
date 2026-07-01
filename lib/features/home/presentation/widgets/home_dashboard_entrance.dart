import 'package:flutter/material.dart';

/// Fade + slide + scale entrance for home dashboard sections.
class HomeDashboardEntrance extends StatefulWidget {
  const HomeDashboardEntrance({
    required this.child,
    super.key,
    this.delayMs = 0,
    this.fromTop = false,
  });

  final Widget child;
  final int delayMs;
  final bool fromTop;

  @override
  State<HomeDashboardEntrance> createState() => _HomeDashboardEntranceState();
}

class _HomeDashboardEntranceState extends State<HomeDashboardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 420 + widget.delayMs),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = 420 + widget.delayMs;
    final start = widget.delayMs / total;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    final beginOffset =
        widget.fromTop ? const Offset(0, -0.08) : const Offset(0, 0.12);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Press-scale feedback for primary dashboard actions.
class HomePressableScale extends StatefulWidget {
  const HomePressableScale({
    required this.child,
    required this.onTap,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<HomePressableScale> createState() => _HomePressableScaleState();
}

class _HomePressableScaleState extends State<HomePressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class HomeSkeletonBox extends StatelessWidget {
  const HomeSkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
