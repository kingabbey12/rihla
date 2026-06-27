import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/routing/data/repositories/route_repository_impl.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

/// Development-only page to inspect route calculation results.
class RouteDebugPage extends ConsumerStatefulWidget {
  const RouteDebugPage({super.key});

  @override
  ConsumerState<RouteDebugPage> createState() => _RouteDebugPageState();
}

class _RouteDebugPageState extends ConsumerState<RouteDebugPage> {
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

  RouteState? _valhallaState;
  String? _valhallaError;

  Future<void> _fetchValhalla() async {
    setState(() {
      _valhallaState = const RouteLoading();
      _valhallaError = null;
    });
    try {
      final repo = RouteRepositoryImpl(ref.read(valhallaRouteServiceProvider));
      final result = await repo.getRoutes(
        const RouteRequest(
          origin: _sampleOrigin,
          destination: _sampleDestination,
        ),
      );
      setState(() => _valhallaState = RouteReady(result));
    } catch (e) {
      setState(() {
        _valhallaState = null;
        _valhallaError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: const Text('Calculate routes (Mock)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _fetchValhalla,
              child: const Text('Calculate routes (Valhalla)'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  const Text('Mock controller:', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildBody(routeState),
                  if (_valhallaState != null || _valhallaError != null) ...[
                    const SizedBox(height: 16),
                    const Text('Valhalla direct:', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (_valhallaError != null) Text(_valhallaError!),
                    if (_valhallaState != null) _buildBody(_valhallaState!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(RouteState state) {
    return switch (state) {
      RouteIdle() => const Text('Idle'),
      RouteLoading() => const Center(child: CircularProgressIndicator()),
      RouteError(:final failure) => Text(failure.message),
      RouteReady(:final result) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: result.routes
              .map(
                (r) => ListTile(
                  title: Text('${r.profile.name} — ${r.distanceKm.toStringAsFixed(1)} km'),
                  subtitle: Text(
                    '${r.durationMinutes} min · ${r.coordinates.length} pts',
                  ),
                ),
              )
              .toList(),
        ),
      RouteSelected(:final selected) => ListTile(
          title: Text('Selected: ${selected.profile.name}'),
        ),
      RouteConfirmed(:final selected) => ListTile(
          title: Text('Confirmed: ${selected.profile.name}'),
        ),
    };
  }
}
