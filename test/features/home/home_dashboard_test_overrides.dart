import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/backend/backend_providers.dart';
import 'package:rihla/features/home/presentation/models/home_journey_brief.dart';
import 'package:rihla/features/home/presentation/models/home_todays_driving_stats.dart';
import 'package:rihla/features/home/presentation/providers/home_dashboard_providers.dart';
import 'package:rihla/features/profile/presentation/providers/profile_providers.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';

/// Provider overrides so home dashboard widgets render in widget tests without
/// account, analytics, or network backends.
List homeDashboardTestOverrides() => [
      homeDisplayNameProvider.overrideWith((ref) => 'Sam'),
      homeLocationAddressProvider.overrideWith((ref) async => 'Dubai, UAE'),
      homeJourneyBriefProvider.overrideWith(_StubJourneyBriefNotifier.new),
      homeTodaysDrivingProvider.overrideWith(
        (ref) async => const HomeTodaysDrivingStats(
          trips: 2,
          distanceKm: 14,
          drivingScore: 82,
          drivingMinutes: 38,
        ),
      ),
      profileDashboardProvider.overrideWith(
        (ref) async => {
          'drivingScore': {'score': 82},
          'statistics': {
            'totalTrips': 2,
            'totalDistanceKm': 14,
            'totalDrivingHours': 1,
          },
        },
      ),
      backendEnabledProvider.overrideWithValue(false),
      searchRecentsProvider.overrideWith(_StubRecents.new),
    ];

class _StubJourneyBriefNotifier extends HomeJourneyBriefNotifier {
  @override
  Future<HomeJourneyBrief> build() async => const HomeJourneyBrief(
        available: true,
        trafficSummary: 'Light traffic in your area',
        weatherWarning: 'Clear skies',
        bestDeparture: 'Good time to depart now',
        roadIncidents: 'No major incidents reported nearby',
        aiRecommendation: 'Sheikh Zayed Road is flowing well',
      );
}

class _StubRecents extends SearchRecentsNotifier {
  @override
  Future<List<SearchPlace>> build() async => const [];
}
