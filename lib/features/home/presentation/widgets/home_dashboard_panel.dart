import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/home/presentation/providers/home_dashboard_providers.dart';
import 'package:rihla/features/home/presentation/widgets/home_ai_journey_brief_card.dart';
import 'package:rihla/features/home/presentation/widgets/home_dashboard_header.dart';
import 'package:rihla/features/home/presentation/widgets/home_dashboard_search_section.dart';
import 'package:rihla/features/home/presentation/widgets/home_map_preview_card.dart';
import 'package:rihla/features/home/presentation/widgets/home_quick_actions_grid.dart';
import 'package:rihla/features/home/presentation/widgets/home_start_navigation_card.dart';
import 'package:rihla/features/home/presentation/widgets/home_todays_driving_card.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/traffic/presentation/providers/traffic_providers.dart';
import 'package:rihla/features/weather/presentation/providers/weather_providers.dart';

/// Scrollable home dashboard content shown over the map when idle.
class HomeDashboardPanel extends ConsumerStatefulWidget {
  const HomeDashboardPanel({super.key});

  @override
  ConsumerState<HomeDashboardPanel> createState() => _HomeDashboardPanelState();
}

class _HomeDashboardPanelState extends ConsumerState<HomeDashboardPanel> {
  bool _bootstrapped = false;

  void _refreshForLocation(double lat, double lng) {
    ref.read(weatherControllerProvider.notifier).fetch(
          latitude: lat,
          longitude: lng,
        );
    ref.read(trafficControllerProvider.notifier).fetchForArea(
          latitude: lat,
          longitude: lng,
        );
    ref.read(homeJourneyBriefProvider.notifier).refresh(
          latitude: lat,
          longitude: lng,
        );
    ref.invalidate(homeLocationAddressProvider);
    ref.invalidate(homeTodaysDrivingProvider);
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapped) {
      _bootstrapped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final location = ref.read(locationControllerProvider);
        if (location is LocationActive) {
          _refreshForLocation(
            location.position.latitude,
            location.position.longitude,
          );
        } else {
          ref.invalidate(homeTodaysDrivingProvider);
        }
      });
    }

    ref.listen(locationControllerProvider, (previous, next) {
      if (next is! LocationActive) return;
      final moved = previous is! LocationActive ||
          previous.position.latitude != next.position.latitude ||
          previous.position.longitude != next.position.longitude;
      if (moved) {
        _refreshForLocation(next.position.latitude, next.position.longitude);
      }
    });

    final bottomInset = 88 + MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: const [
        HomeDashboardHeader(),
        SizedBox(height: 14),
        HomeDashboardSearchSection(),
        SizedBox(height: 16),
        HomeStartNavigationCard(),
        SizedBox(height: 16),
        HomeAiJourneyBriefCard(),
        SizedBox(height: 16),
        HomeQuickActionsGrid(),
        SizedBox(height: 16),
        HomeTodaysDrivingCard(),
        SizedBox(height: 16),
        HomeMapPreviewCard(),
        SizedBox(height: 8),
      ],
    );
  }
}
