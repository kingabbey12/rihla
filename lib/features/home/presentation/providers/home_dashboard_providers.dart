import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/backend/backend_providers.dart';
import 'package:rihla/features/account/domain/models/account_state.dart';
import 'package:rihla/features/account/presentation/providers/account_providers.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/home/presentation/models/home_journey_brief.dart';
import 'package:rihla/features/home/presentation/models/home_todays_driving_stats.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_selectors.dart';
import 'package:rihla/core/backend/mappers/profile_backend_mapper.dart';
import 'package:rihla/features/profile/presentation/providers/profile_providers.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/traffic/presentation/providers/traffic_providers.dart';
import 'package:rihla/features/weather/presentation/providers/weather_providers.dart';

/// Whether the idle home dashboard overlay should be visible.
final homeDashboardVisibleProvider = Provider<bool>((ref) {
  final isNavigating = ref.watch(navigationIsActiveProvider);
  final journey = ref.watch(journeyControllerProvider);
  final exploreActive = ref.watch(exploreActiveProvider);
  final emergencyActive = ref.watch(emergencyActiveProvider);
  return !isNavigating &&
      journey is JourneyIdle &&
      !exploreActive &&
      !emergencyActive;
});

/// When false, the dashboard collapses to reveal the full map.
final homeDashboardExpandedProvider =
    NotifierProvider<HomeDashboardExpandedNotifier, bool>(
  HomeDashboardExpandedNotifier.new,
);

class HomeDashboardExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void expand() => state = true;
  void collapse() => state = false;
}

final homeDisplayNameProvider = Provider<String>((ref) {
  final account = ref.watch(accountControllerProvider);
  return switch (account) {
    AccountSignedIn(:final profile, :final session) =>
      profile.name?.trim().isNotEmpty == true
          ? profile.name!.trim()
          : (session.displayName?.trim().isNotEmpty == true
              ? session.displayName!.trim()
              : ''),
    AccountGuest(:final session) => session.displayName?.trim() ?? '',
    _ => '',
  };
});

final homeLocationAddressProvider = FutureProvider<String>((ref) async {
  final location = ref.watch(locationControllerProvider);
  if (location is! LocationActive) {
    return '';
  }
  final pos = location.position;
  try {
    final place = await ref.read(searchServiceProvider).reverseGeocode(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
    if (place != null) {
      final name = place.name.trim();
      if (name.isNotEmpty) return name;
      final address = place.address.trim();
      if (address.isNotEmpty) return address;
    }
  } catch (_) {
    // Fall through to coordinates label.
  }
  return '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
});

final homeJourneyBriefProvider =
    AsyncNotifierProvider<HomeJourneyBriefNotifier, HomeJourneyBrief>(
  HomeJourneyBriefNotifier.new,
);

class HomeJourneyBriefNotifier extends AsyncNotifier<HomeJourneyBrief> {
  @override
  Future<HomeJourneyBrief> build() async => const HomeJourneyBrief.unavailable();

  Future<void> refresh({required double latitude, required double longitude}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final traffic = ref.read(trafficSnapshotProvider);
      final weather = ref.read(weatherSnapshotProvider);

      String? aiText;
      if (ref.read(backendEnabledProvider)) {
        try {
          final response =
              await ref.read(aiBackendDatasourceProvider).journeyAdvice({
            'message':
                'Provide a concise journey brief for my current location including traffic, weather, best departure time, incidents, and one recommendation.',
            'latitude': latitude,
            'longitude': longitude,
          });
          aiText = response['reply'] as String? ??
              response['content'] as String? ??
              response['explanation'] as String?;
        } catch (_) {
          aiText = null;
        }
      }

      return _compose(traffic, weather, aiText);
    });
  }

  HomeJourneyBrief _compose(
    TrafficSnapshot? traffic,
    dynamic weather,
    String? aiText,
  ) {
    final trafficSummary = traffic == null
        ? null
        : switch (traffic.density) {
            TrafficDensity.freeFlow => 'Free-flowing roads nearby',
            TrafficDensity.light => 'Light traffic in your area',
            TrafficDensity.moderate => 'Moderate traffic nearby',
            TrafficDensity.heavy => 'Heavy traffic — allow extra time',
            TrafficDensity.standstill => 'Standstill traffic reported',
          };

    String? weatherWarning;
    String? bestDeparture;
    if (weather != null) {
      final current = weather.current;
      weatherWarning = current.summary;
      if (current.rainProbabilityPercent >= 40) {
        weatherWarning =
            '${current.summary} — ${current.rainProbabilityPercent.round()}% rain chance';
      }
      final hour = DateTime.now().hour;
      if (hour >= 7 && hour <= 9) {
        bestDeparture = 'Leave after 9:30 AM to avoid morning rush';
      } else if (hour >= 16 && hour <= 18) {
        bestDeparture = 'Leave before 4:30 PM to avoid evening rush';
      } else {
        bestDeparture = 'Good time to depart now';
      }
    }

    final delay = traffic?.travelDelayMinutes;
    final roadIncidents = delay != null && delay > 0
        ? 'About $delay min delay on nearby corridors'
        : 'No major incidents reported nearby';

    final hasSignal = trafficSummary != null ||
        weatherWarning != null ||
        (aiText != null && aiText.trim().isNotEmpty);

    if (!hasSignal) {
      return const HomeJourneyBrief.unavailable();
    }

    return HomeJourneyBrief(
      available: true,
      trafficSummary: trafficSummary,
      weatherWarning: weatherWarning,
      bestDeparture: bestDeparture,
      roadIncidents: roadIncidents,
      aiRecommendation: aiText?.trim().isNotEmpty == true ? aiText!.trim() : null,
    );
  }
}

final homeTodaysDrivingProvider =
    FutureProvider<HomeTodaysDrivingStats>((ref) async {
  final dashboard = await ref.watch(profileDashboardProvider.future);
  final drivingScore = ProfileBackendMapper.drivingScore(dashboard);

  final journeys =
      await ref.watch(analyticsRepositoryProvider).journeys(limit: 40);
  final startOfDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  var trips = 0;
  var distanceKm = 0.0;
  var drivingMinutes = 0;

  for (final row in journeys) {
    final computedAt = row['computedAt'] ?? row['createdAt'];
    final date =
        computedAt != null ? DateTime.tryParse(computedAt as String) : null;
    if (date == null || date.isBefore(startOfDay)) continue;
    trips++;
    distanceKm += (row['distanceKm'] as num?)?.toDouble() ?? 0;
    final drivingSeconds = (row['drivingSeconds'] as num?)?.toInt() ??
        (((row['durationMinutes'] as num?)?.toInt() ?? 0) * 60);
    drivingMinutes += drivingSeconds ~/ 60;
  }

  return HomeTodaysDrivingStats(
    trips: trips,
    distanceKm: distanceKm,
    drivingScore: drivingScore,
    drivingMinutes: drivingMinutes,
  );
});