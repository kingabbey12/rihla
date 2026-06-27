import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/map/domain/entities/map_camera.dart';
import 'package:rihla/features/map/domain/utils/map_scale_calculator.dart';

/// A minimal scale bar that reflects the current zoom + latitude.
class MapScaleIndicator extends StatelessWidget {
  const MapScaleIndicator({
    required this.camera,
    this.maxWidth = 96,
    super.key,
  });

  final MapCamera camera;

  /// Maximum width of the scale bar in logical pixels.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final metersPerPixel =
        MapScaleCalculator.metersPerPixel(camera.latitude, camera.zoom);
    if (metersPerPixel <= 0 || metersPerPixel.isInfinite) {
      return const SizedBox.shrink();
    }

    final maxMeters = metersPerPixel * maxWidth;
    final niceMeters = MapScaleCalculator.niceDistance(maxMeters);
    final barWidth = (niceMeters / metersPerPixel).clamp(0.0, maxWidth);
    final color = context.colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          MapScaleCalculator.label(niceMeters),
          style: context.textTheme.labelSmall?.copyWith(
            color: color,
            shadows: [
              Shadow(
                color: context.colorScheme.surface,
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: barWidth,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border(
              left: BorderSide(color: color, width: 2),
              right: BorderSide(color: color, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
