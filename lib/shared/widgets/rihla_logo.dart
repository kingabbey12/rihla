import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rihla/core/constants/asset_paths.dart';

/// Display modes for [RihlaLogo].
enum RihlaLogoVariant {
  iconOnly,
  wordmarkOnly,
  full,
}

/// Brand logo widget. Swap SVG assets in [AssetPaths] to update branding.
class RihlaLogo extends StatefulWidget {
  const RihlaLogo({
    super.key,
    this.variant = RihlaLogoVariant.full,
    this.iconSize = 72,
    this.wordmarkHeight = 36,
    this.animated = false,
    this.color,
  });

  final RihlaLogoVariant variant;
  final double iconSize;
  final double wordmarkHeight;
  final bool animated;
  final Color? color;

  @override
  State<RihlaLogo> createState() => _RihlaLogoState();
}

class _RihlaLogoState extends State<RihlaLogo>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scale;
  Animation<double>? _opacity;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
      _scale = Tween<double>(begin: 0.85, end: 1).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeOutCubic),
      );
      _opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeIn),
      );
      _controller!.forward();
    }
  }

  @override
  void didUpdateWidget(RihlaLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && _controller == null) {
      initState();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildLogoContent(context);
    if (!widget.animated || _controller == null) {
      return content;
    }
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) => Opacity(
        opacity: _opacity!.value,
        child: Transform.scale(scale: _scale!.value, child: child),
      ),
      child: content,
    );
  }

  Widget _buildLogoContent(BuildContext context) {
    final wordmarkColor = widget.color ?? Theme.of(context).colorScheme.onSurface;

    switch (widget.variant) {
      case RihlaLogoVariant.iconOnly:
        return SvgPicture.asset(
          AssetPaths.rihlaIcon,
          width: widget.iconSize,
          height: widget.iconSize,
        );
      case RihlaLogoVariant.wordmarkOnly:
        return SvgPicture.asset(
          AssetPaths.rihlaWordmark,
          height: widget.wordmarkHeight,
          theme: SvgTheme(currentColor: wordmarkColor),
        );
      case RihlaLogoVariant.full:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              AssetPaths.rihlaIcon,
              width: widget.iconSize,
              height: widget.iconSize,
            ),
            const SizedBox(height: 16),
            SvgPicture.asset(
              AssetPaths.rihlaWordmark,
              height: widget.wordmarkHeight,
              theme: SvgTheme(currentColor: wordmarkColor),
            ),
          ],
        );
    }
  }
}
