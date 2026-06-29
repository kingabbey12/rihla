import 'package:flutter/material.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_copilot_map_overlay.dart';
import 'package:rihla/features/emergency/presentation/widgets/emergency_map_overlay.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_map_overlay.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_map_overlay.dart';
import 'package:rihla/features/live_journey/presentation/widgets/journey_dashboard_map_overlay.dart';
import 'package:rihla/features/navigation/presentation/widgets/navigation_controls_overlay.dart';
import 'package:rihla/features/navigation/presentation/widgets/navigation_speed_limit_overlay.dart';
import 'package:rihla/features/navigation/presentation/widgets/navigation_turn_banner_overlay.dart';
import 'package:rihla/features/routing/presentation/widgets/route_map_overlay.dart';
import 'package:rihla/features/safety/presentation/widgets/safety_alert_banner_overlay.dart';
import 'package:rihla/features/safety/presentation/widgets/safety_map_overlay.dart';
import 'package:rihla/features/uae/presentation/widgets/uae_alert_banner.dart';
import 'package:rihla/features/search/presentation/widgets/map_search_bar.dart';

/// Feature overlays stacked above the map surface.
class MapOverlaysStack extends StatelessWidget {
  const MapOverlaysStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(top: 0, left: 0, right: 0, child: MapSearchBar()),
        Positioned.fill(child: JourneyMapOverlay()),
        Positioned.fill(child: ExploreMapOverlay()),
        Positioned.fill(child: EmergencyMapOverlay()),
        Positioned.fill(child: RouteMapOverlay()),
        Positioned.fill(child: NavigationControlsOverlay()),
        NavigationTurnBannerOverlay(),
        Positioned.fill(child: NavigationSpeedLimitOverlay()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 120,
          child: UaeAlertBanner(),
        ),
        SafetyAlertBannerOverlay(),
        SafetyMapOverlay(),
        AiCopilotMapOverlay(),
        JourneyDashboardMapOverlay(),
      ],
    );
  }
}
