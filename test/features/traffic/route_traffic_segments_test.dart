import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/navigation/presentation/services/navigation_voice_coordinator.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/traffic/presentation/utils/route_traffic_segments.dart';

void main() {
  test('buildRouteTrafficSegments splits route into coloured slices', () {
    final route = List.generate(
      10,
      (i) => RouteCoordinate(latitude: 25.0 + i * 0.001, longitude: 55.0),
    );

    final segments = buildRouteTrafficSegments(
      route: route,
      snapshot: TrafficSnapshot(
        density: TrafficDensity.heavy,
        averageSpeedKmh: 30,
        travelDelayMinutes: 12,
        etaDelayMinutes: 8,
        incidents: const [],
        observedAt: DateTime(2026, 1, 1),
      ),
    );

    expect(segments.length, greaterThan(1));
    expect(segments.first.coordinates.length, greaterThanOrEqualTo(2));
  });

  test('voice coordinator builds distance-tiered English prompts', () {
    expect(
      NavigationVoiceCoordinator.buildPrompt(
        distanceMeters: 1200,
        instruction: 'Turn right',
        languageCode: 'en',
      ),
      contains('kilometers'),
    );
    expect(
      NavigationVoiceCoordinator.buildPrompt(
        distanceMeters: 200,
        instruction: 'Turn right',
        languageCode: 'en',
      ),
      contains('200 meters'),
    );
    expect(
      NavigationVoiceCoordinator.buildPrompt(
        distanceMeters: 40,
        instruction: 'Turn right',
        languageCode: 'en',
      ),
      'Turn right',
    );
  });
}
