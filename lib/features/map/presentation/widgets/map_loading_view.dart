import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Full-bleed loading state shown while the map style and tiles initialize.
///
/// Renders a map-like skeleton (city blocks + roads) with an animated shimmer
/// sweep so the user never sees a blank white surface during the tile load.
class MapLoadingView extends StatefulWidget {
  const MapLoadingView({super.key});

  @override
  State<MapLoadingView> createState() => _MapLoadingViewState();
}

class _MapLoadingViewState extends State<MapLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Explicit map-like tones so the skeleton reads clearly against the surface.
    final blockColor =
        isDark ? const Color(0xFF1A2230) : const Color(0xFFE3E8EE);
    final roadColor =
        isDark ? const Color(0xFF2B3543) : const Color(0xFFF6F8FB);

    return ColoredBox(
      color: blockColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _MapSkeletonPainter(
              blockColor: blockColor,
              roadColor: roadColor,
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: _ShimmerSweepPainter(
                progress: _controller.value,
                highlight: Colors.white.withValues(alpha: isDark ? 0.04 : 0.35),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.mapLoading,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a stylized grid of city blocks and roads for the loading skeleton.
class _MapSkeletonPainter extends CustomPainter {
  _MapSkeletonPainter({required this.blockColor, required this.roadColor});

  final Color blockColor;
  final Color roadColor;

  @override
  void paint(Canvas canvas, Size size) {
    final blockPaint = Paint()..color = blockColor;
    final roadPaint = Paint()..color = roadColor;

    const spacing = 96.0;
    const roadWidth = 16.0;

    canvas.drawRect(Offset.zero & size, blockPaint);

    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawRect(
        Rect.fromLTWH(x - roadWidth / 2, 0, roadWidth, size.height),
        roadPaint,
      );
    }
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawRect(
        Rect.fromLTWH(0, y - roadWidth / 2, size.width, roadWidth),
        roadPaint,
      );
    }

    final diagonal = Paint()
      ..color = roadColor
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(-40, size.height * 0.72),
      Offset(size.width * 0.85, -40),
      diagonal,
    );
  }

  @override
  bool shouldRepaint(_MapSkeletonPainter oldDelegate) =>
      oldDelegate.blockColor != blockColor || oldDelegate.roadColor != roadColor;
}

/// Paints a diagonal translucent highlight band that sweeps across the skeleton.
class _ShimmerSweepPainter extends CustomPainter {
  _ShimmerSweepPainter({required this.progress, required this.highlight});

  final double progress;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final dx = (progress * 2 - 0.5) * size.width;
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        highlight.withValues(alpha: 0),
        highlight,
        highlight.withValues(alpha: 0),
      ],
      stops: const [0.35, 0.5, 0.65],
    );
    final shaderRect = Rect.fromLTWH(dx - size.width, 0, size.width * 2, size.height);
    final paint = Paint()..shader = gradient.createShader(shaderRect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ShimmerSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
