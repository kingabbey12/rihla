import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

/// Development-only page to inspect route calculation results.
class RouteDebugPage extends ConsumerWidget {
  const RouteDebugPage({super.key});

  static const _sampleOrigin = RoutePoint(
    latitude: 24.7136,
    longitude: 46.6753,
    name: 'Origin',
  );
  static const _sampleDestination = RoutePoint(
    latitude: 24.7113,
    longitude: 46.6743,
    name: 'Kingdom Centre',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Route Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () => ref.read(routeControllerProvider.notifier).fetchRoutes(
                    const RouteRequest(
                      origin: _sampleOrigin,
                      destination: _sampleDestination,
                    ),
                  ),
              child: const Text('Calculate routes (Valhalla)'),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(context, routeState)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RouteState state) {
    return switch (state) {
      RouteIdle() => const Center(child: Text('Tap to calculate routes')),
      RouteLoading() => const Center(child: CircularProgressIndicator()),
      RouteError(:final failure) => Center(child: Text(failure.message)),
      RouteReady(:final result) => ListView(
          children: result.routes
              .map(
                (r) => ListTile(
                  title: Text('${r.profile.name} — ${r.distanceKm.toStringAsFixed(1)} km'),
                  subtitle: Text(
                    '${r.durationMinutes} min · '
                    '${r.coordinates.length} points · '
                    'score ${r.journeyScore.round()}',
                  ),
                ),
              )
              .toList(),
        ),
      RouteSelected(:final selected) => ListView(
          children: [
            ListTile(
              title: Text('Selected: ${selected.profile.name}'),
              subtitle: Text('${selected.distanceKm.toStringAsFixed(1)} km'),
            ),
          ],
        ),
    };
  }
}
