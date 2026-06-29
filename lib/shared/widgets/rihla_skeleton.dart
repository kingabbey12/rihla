import 'package:flutter/material.dart';
import 'package:rihla/shared/design/rihla_gradients.dart';
import 'package:rihla/shared/design/rihla_radii.dart';
import 'package:rihla/shared/design/rihla_spacing.dart';

/// An animated shimmer placeholder block. Use instead of bare spinners so
/// loading states communicate the shape of the content that's arriving.
class RihlaSkeleton extends StatefulWidget {
  const RihlaSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = RihlaRadii.smAll,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<RihlaSkeleton> createState() => _RihlaSkeletonState();
}

class _RihlaSkeletonState extends State<RihlaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.onSurface.withValues(alpha: 0.08);
    final highlight = scheme.onSurface.withValues(alpha: 0.16);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: RihlaGradients.shimmer(base, highlight, _controller.value),
          ),
        );
      },
    );
  }
}

/// A column of skeleton "cards" approximating a list while data loads.
class RihlaSkeletonList extends StatelessWidget {
  const RihlaSkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 76,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(itemCount, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: RihlaSpacing.md),
          child: Row(
            children: [
              RihlaSkeleton(
                width: itemHeight - 16,
                height: itemHeight - 16,
                borderRadius: RihlaRadii.mdAll,
              ),
              const SizedBox(width: RihlaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    RihlaSkeleton(height: 14),
                    SizedBox(height: RihlaSpacing.sm),
                    RihlaSkeleton(width: 160, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
