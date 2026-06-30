import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_copilot_map_overlay.dart';
import 'package:rihla/features/emergency/presentation/widgets/emergency_map_overlay.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_map_overlay.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_map_overlay.dart';
import 'package:rihla/features/live_journey/presentation/widgets/journey_dashboard_map_overlay.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_selectors.dart';
import 'package:rihla/features/navigation/presentation/widgets/navigation_controls_overlay.dart';
import 'package:rihla/features/navigation/presentation/widgets/navigation_speed_limit_overlay.dart';
import 'package:rihla/features/navigation/presentation/widgets/navigation_turn_banner_overlay.dart';
import 'package:rihla/features/routing/presentation/widgets/route_map_overlay.dart';
import 'package:rihla/features/safety/presentation/widgets/safety_alert_banner_overlay.dart';
import 'package:rihla/features/safety/presentation/widgets/safety_map_overlay.dart';
import 'package:rihla/features/uae/presentation/widgets/uae_alert_banner.dart';
import 'package:rihla/features/search/presentation/widgets/map_search_bar.dart';

/// Feature overlays stacked above the map surface.
class MapOverlaysStack extends ConsumerWidget {
  const MapOverlaysStack({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Minimal navigation view: while actively driving, keep only the essential
    // guidance (turn banner, speed limit, current speed, End Trip controls) and
    // hide map clutter (AI copilot, safety markers, UAE alert banner) so the
    // route ahead stays visible.
    final isNavigating = ref.watch(navigationIsActiveProvider);

    return Stack(
      children: [
        const Positioned(top: 0, left: 0, right: 0, child: MapSearchBar()),
        const Positioned.fill(child: JourneyMapOverlay()),
        const Positioned.fill(child: ExploreMapOverlay()),
        const Positioned.fill(child: EmergencyMapOverlay()),
        const Positioned.fill(child: RouteMapOverlay()),
        const Positioned.fill(child: NavigationControlsOverlay()),
        const NavigationTurnBannerOverlay(),
        const Positioned.fill(child: NavigationSpeedLimitOverlay()),
        if (!isNavigating)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: UaeAlertBanner(),
          ),
        if (!isNavigating) const SafetyAlertBannerOverlay(),
        if (!isNavigating) const SafetyMapOverlay(),
        if (!isNavigating) const AiCopilotMapOverlay(),
        if (!isNavigating) const JourneyDashboardMapOverlay(),
      ],
    );
  }
}
