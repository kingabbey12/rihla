import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/map/domain/entities/map_style_variant.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';

/// Hidden developer overlay: FPS, zoom, camera, style, coords, GPS accuracy.
///
/// The caller is responsible for only mounting this in debug mode.
class MapDebugOverlay extends ConsumerStatefulWidget {
  const MapDebugOverlay({super.key});

  @override
  ConsumerState<MapDebugOverlay> createState() => _MapDebugOverlayState();
}

class _MapDebugOverlayState extends ConsumerState<MapDebugOverlay> {
  double _fps = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (timings.isEmpty || !mounted) return;
    var totalMicros = 0;
    for (final t in timings) {
      totalMicros += t.totalSpan.inMicroseconds;
    }
    final avgMicros = totalMicros / timings.length;
    if (avgMicros <= 0) return;
    final fps = (1000000 / avgMicros).clamp(0, 120).toDouble();
    setState(() => _fps = fps);
  }

  @override
  Widget build(BuildContext context) {
    final camera = ref.watch(mapCameraProvider);
    final variant = ref.watch(mapStyleVariantProvider);
    final locationState = ref.watch(locationControllerProvider);

    final accuracy = switch (locationState) {
      LocationActive(:final position) =>
        '${position.accuracy.toStringAsFixed(1)} m',
      _ => '—',
    };
    final coords = switch (locationState) {
      LocationActive(:final position) =>
        '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}',
      _ => '—',
    };

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFFB9F6CA),
            fontSize: 11,
            fontFamily: 'monospace',
            height: 1.4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FPS       ${_fps.toStringAsFixed(0)}'),
              Text('ZOOM      ${camera.zoom.toStringAsFixed(2)}'),
              Text(
                'CAMERA    ${camera.latitude.toStringAsFixed(5)}, '
                '${camera.longitude.toStringAsFixed(5)}',
              ),
              Text('BEARING   ${camera.bearing.toStringAsFixed(1)}°'),
              Text(
                'STYLE     ${variant == MapStyleVariant.dark ? 'DARK' : 'LIGHT'}',
              ),
              Text('GPS       $coords'),
              Text('ACCURACY  $accuracy'),
            ],
          ),
        ),
      ),
    );
  }
}
