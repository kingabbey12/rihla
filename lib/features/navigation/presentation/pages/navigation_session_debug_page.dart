import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/entities/journey_metrics.dart';
import 'package:rihla/features/journey/domain/entities/journey_score.dart';
import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/journey/domain/models/ai_journey_summary.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/routing/data/repositories/route_repository_impl.dart';
import 'package:rihla/features/routing/data/services/mock_route_service.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';

/// Development-only page to inspect the full navigation session.
///
/// Not linked from the main UI. Navigate directly to `/debug/navigation`.
class NavigationSessionDebugPage extends ConsumerStatefulWidget {
  const NavigationSessionDebugPage({super.key});

  @override
  ConsumerState<NavigationSessionDebugPage> createState() =>
      _NavigationSessionDebugPageState();
}

class _NavigationSessionDebugPageState
    extends ConsumerState<NavigationSessionDebugPage> {
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

  String? _error;

  JourneySummary _sampleJourney() {
    const components = JourneyScoreComponents(
      safety: 85,
      traffic: 72,
      weather: 90,
      roadConditions: 78,
      fuelEfficiency: 80,
      vehicleStatus: 92,
    );
    return JourneySummary(
      destination: const JourneyEndpoint(
        id: 'dest',
        name: 'Kingdom Centre',
        address: 'King Fahd Road',
        latitude: 24.7113,
        longitude: 46.6743,
      ),
      origin: const JourneyEndpoint(
        id: 'origin',
        name: 'Current Location',
        address: 'Riyadh',
        latitude: 24.7136,
        longitude: 46.6753,
      ),
      metrics: const JourneyMetrics(
        distanceKm: 8.5,
        durationMinutes: 18,
        weatherSummary: 'Clear skies',
        temperatureCelsius: 32,
        trafficLevel: TrafficLevel.moderate,
        fuelEstimateLiters: 0.6,
        batteryEstimatePercent: 10,
        roadCondition: RoadConditionLevel.good,
        departureSuggestions: ['Leave now'],
      ),
      score: JourneyScore(
        journeyScore: 82,
        safetyScore: 84,
        components: components,
      ),
      aiSummary: const AiJourneySummary(
        headline: 'Debug journey',
        body: 'Sample session for development.',
        highlights: ['Simulation mode'],
      ),
    );
  }

  Future<void> _startSampleSession() async {
    setState(() => _error = null);
    try {
      final repo = RouteRepositoryImpl(MockRouteService());
      final result = await repo.getRoutes(
        const RouteRequest(
          origin: _sampleOrigin,
          destination: _sampleDestination,
        ),
      );
      final route = result.primary;
      if (route == null) {
        setState(() => _error = 'No routes returned');
        return;
      }
      await ref.read(navigationSessionControllerProvider.notifier).startSession(
            journey: _sampleJourney(),
            route: route,
          );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(navigationSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Session Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: _startSampleSession,
              child: const Text('Start sample session'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref
                  .read(navigationSessionControllerProvider.notifier)
                  .stopSession(),
              child: const Text('Stop session'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: switch (sessionState) {
                NavigationSessionInactive() =>
                  const Center(child: Text('No active session')),
                NavigationSessionActive(:final session) =>
                  _SessionDetails(session: session),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionDetails extends ConsumerWidget {
  const _SessionDetails({required this.session});

  final NavigationSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(navigationSessionControllerProvider.notifier);

    return ListView(
      children: [
        _row('Session ID', session.sessionId),
        _row('Status', session.status.name),
        _row('Destination', session.journey.destination.name),
        _row('Route profile', session.route.profile.name),
        _row('Route distance', '${session.route.distanceKm.toStringAsFixed(1)} km'),
        _row('Current road', session.currentRoad),
        _row('Maneuver type', session.currentManeuver.type.name),
        _row('Next road', session.currentManeuver.nextRoad),
        _row('Maneuver', session.currentManeuver.instruction),
        _row(
          'Maneuver distance',
          '${session.currentManeuver.distanceToManeuverKm.toStringAsFixed(2)} km',
        ),
        _row('Maneuver placeholder', '${session.currentManeuver.isPlaceholder}'),
        _row(
          'Position',
          '${session.currentPosition.latitude.toStringAsFixed(5)}, '
          '${session.currentPosition.longitude.toStringAsFixed(5)}',
        ),
        _row('Accuracy', '${session.currentPosition.accuracy} m'),
        _row(
          'Distance traveled',
          '${session.distanceTraveledKm.toStringAsFixed(2)} km',
        ),
        _row(
          'Remaining distance',
          '${session.remainingDistanceKm.toStringAsFixed(2)} km',
        ),
        _row(
          'Remaining duration',
          '${session.remainingDuration.inMinutes} min',
        ),
        _row('ETA', session.eta.toIso8601String()),
        _row('Speed', '${session.speedKmh.toStringAsFixed(1)} km/h'),
        _row('Heading', '${session.headingDegrees.toStringAsFixed(1)}°'),
        _row(
          'Route progress',
          '${session.routeProgressPercent.toStringAsFixed(1)}%',
        ),
        _row('Off route', '${session.isOffRoute}'),
        _row('Reroute state', session.rerouteState.runtimeType.toString()),
        _row('Speed limit', '${session.speedLimit.limitKmh} km/h'),
        _row('Lane lanes', '${session.laneGuidance.lanes.length}'),
        _row('Simulation', session.simulation.playback.name),
        _row('Sim speed', '${session.simulation.speedMultiplier}x'),
        _row('Maneuver steps', '${session.maneuverSteps.length}'),
        _row('Last updated', session.lastUpdatedAt.toIso8601String()),
        SwitchListTile(
          title: const Text('Voice enabled'),
          value: session.voiceEnabled,
          onChanged: notifier.setVoiceEnabled,
        ),
        SwitchListTile(
          title: const Text('Simulation mode'),
          value: session.simulationMode,
          onChanged: notifier.setSimulationMode,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.playSimulation(),
                child: const Text('Play'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.pauseSimulation(),
                child: const Text('Pause'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.resumeSimulation(),
                child: const Text('Resume'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.setSimulationSpeed(1),
                child: const Text('1x'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.setSimulationSpeed(2),
                child: const Text('2x'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.setSimulationSpeed(4),
                child: const Text('4x'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => notifier.simulateDeviation(),
          child: const Text('Simulate deviation'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.pauseSession(),
                child: const Text('Pause session'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => notifier.resumeSession(),
                child: const Text('Resume session'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
