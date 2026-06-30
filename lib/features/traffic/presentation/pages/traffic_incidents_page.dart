import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/traffic/domain/models/traffic_state.dart';
import 'package:rihla/features/traffic/presentation/providers/traffic_providers.dart';
import 'package:rihla/shared/ui/rihla_floating_card.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';
import 'package:rihla/shared/widgets/empty_screen.dart';

/// Live Traffic & Incidents screen matching the production reference.
class TrafficIncidentsPage extends ConsumerStatefulWidget {
  const TrafficIncidentsPage({super.key});

  @override
  ConsumerState<TrafficIncidentsPage> createState() =>
      _TrafficIncidentsPageState();
}

class _TrafficIncidentsPageState extends ConsumerState<TrafficIncidentsPage> {
  /// True when we could not resolve any position to centre the area query on.
  bool _noLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only auto-fetch when no route already populated a snapshot.
      if (ref.read(trafficControllerProvider) is TrafficIdle) {
        _loadAreaTraffic();
      }
    });
  }

  Future<void> _loadAreaTraffic() async {
    await _ensureLocation();
    final origin = _resolveOrigin();
    if (origin == null) {
      // No GPS / map fix yet — show a retryable empty state.
      if (mounted) setState(() => _noLocation = true);
      return;
    }
    if (mounted) setState(() => _noLocation = false);
    await ref.read(trafficControllerProvider.notifier).fetchForArea(
          latitude: origin.latitude,
          longitude: origin.longitude,
        );
  }

  Future<void> _ensureLocation() async {
    final location = ref.read(locationControllerProvider);
    if (location is LocationActive) return;
    try {
      await ref
          .read(locationControllerProvider.notifier)
          .fetchCurrentPosition();
    } catch (_) {
      // Permission denied / GPS off — fall back to map camera in _resolveOrigin.
    }
  }

  /// Best available centre point: live GPS fix, last-known fix, then the map
  /// camera once it has resolved away from the (0,0) sentinel.
  ({double latitude, double longitude})? _resolveOrigin() {
    final location = ref.read(locationControllerProvider);
    final position = switch (location) {
      LocationActive(:final position) => position,
      LocationError(:final lastKnownPosition) => lastKnownPosition,
      _ => null,
    };
    if (position != null) {
      return (latitude: position.latitude, longitude: position.longitude);
    }
    final camera = ref.read(mapCameraProvider);
    if (camera.latitude == 0 && camera.longitude == 0) return null;
    return (latitude: camera.latitude, longitude: camera.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final trafficState = ref.watch(trafficControllerProvider);

    if (_noLocation || trafficState is TrafficError) {
      return _scaffold(
        context,
        EmptyScreen(
          title: 'Traffic data unavailable',
          message:
              'Live traffic will appear when your location and network are available.',
          icon: Icons.traffic_outlined,
          actionLabel: 'Retry',
          onAction: _loadAreaTraffic,
        ),
      );
    }

    if (trafficState is TrafficLoading || trafficState is TrafficIdle) {
      return _scaffold(
        context,
        const Center(child: CircularProgressIndicator()),
      );
    }

    final snapshot = (trafficState as TrafficReady).snapshot;
    final theme = Theme.of(context);
    var filter = 'All';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Traffic & Incidents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 280,
            child: Stack(
              children: [
                Container(
                  color: const Color(0xFFE9EDF2),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _TrafficMapPainter(incidentCount: snapshot.incidents.length),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in ['All', 'Accidents', 'Hazards', 'Road Closures'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f),
                              selected: filter == f,
                              onSelected: (_) => filter = f,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RihlaFloatingCard(
                  child: Row(
                    children: [
                      Icon(Icons.traffic, color: RihlaReferenceTokens.mapTeal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Average speed ${snapshot.averageSpeedKmh.toStringAsFixed(0)} km/h',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${snapshot.travelDelayMinutes} min delay · ${snapshot.incidents.length} incidents',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final incident in snapshot.incidents)
                  RihlaFloatingCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                incident.type,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(incident.description),
                              Text(
                                '+${incident.delayMinutes} min delay',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Scaffold _scaffold(BuildContext context, Widget body) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Traffic & Incidents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: body,
    );
  }
}

class _TrafficMapPainter extends CustomPainter {
  _TrafficMapPainter({required this.incidentCount});

  final int incidentCount;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.45), road);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.5, size.height), road);

    final hazard = Paint()..color = Colors.orange.shade700;
    for (var i = 0; i < incidentCount.clamp(1, 4); i++) {
      final x = size.width * (0.25 + i * 0.18);
      final y = size.height * (0.35 + (i % 2) * 0.15);
      canvas.drawCircle(Offset(x, y), 10, hazard);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
