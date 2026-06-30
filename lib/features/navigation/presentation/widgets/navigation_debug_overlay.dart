import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_controller.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

/// Debug-only overlay showing navigation state-machine fields on the map.
class NavigationDebugOverlay extends ConsumerWidget {
  const NavigationDebugOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationSessionControllerProvider);
    final routeState = ref.watch(routeControllerProvider);
    final journeyState = ref.watch(journeyControllerProvider);
    final previewActive = ref.watch(routePreviewActiveProvider);

    final lines = <String>[
      'NAV STATE   ${navState.runtimeType}',
      'ROUTE       ${routeState.runtimeType}',
      'JOURNEY     ${journeyState.runtimeType}',
      'PREVIEW     $previewActive',
    ];

    if (navState is NavigationSessionActive) {
      final s = navState.session;
      lines.addAll([
        'STATUS      ${s.status.name}',
        'VOICE       ${s.voiceEnabled ? 'ON' : 'OFF'}',
        'ROAD        ${s.currentRoad}',
        'MANEUVER    ${s.currentManeuver.instruction}',
        'DIST→TURN   ${(s.currentManeuver.distanceToManeuverKm * 1000).round()} m',
        'REMAINING   ${s.remainingDistanceKm.toStringAsFixed(2)} km',
        'SPEED       ${s.speedKmh.round()} km/h',
        'OFF ROUTE   ${s.isOffRoute}',
        'REROUTE     ${s.rerouteState.runtimeType}',
      ]);
    }

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.4)),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFF7DD3FC),
            fontSize: 10,
            fontFamily: 'monospace',
            height: 1.35,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final line in lines) Text(line)],
          ),
        ),
      ),
    );
  }
}
