import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/observability/analytics_event.dart';
import 'package:rihla/core/observability/analytics_service.dart';
import 'package:rihla/core/observability/crash_reporter.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/search/domain/entities/saved_place_kind.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/models/search_query_state.dart';
import 'package:rihla/features/search/domain/repositories/search_repository.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end wiring check: product flows emit sanitized analytics + breadcrumbs
/// through the observability layer.
void main() {
  late BufferingAnalyticsService analytics;

  Future<ProviderContainer> buildContainer(SearchRepository repo) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        analyticsServiceProvider.overrideWithValue(analytics),
        searchRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => analytics = BufferingAnalyticsService());

  test('defaults are privacy-safe no-op implementations', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fresh = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(fresh.dispose);
    expect(fresh.read(analyticsServiceProvider), isA<NoOpAnalyticsService>());
    expect(fresh.read(crashReporterProvider), isA<NoOpCrashReporter>());
  });

  test('successful search emits searchSuccess', () async {
    final container = await buildContainer(_OkRepo());
    container.read(searchQueryTextProvider.notifier).set('mall');
    container.read(searchQueryStateProvider.notifier).onQueryChanged('mall');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(container.read(searchQueryStateProvider), isA<SearchQueryResults>());
    expect(
      analytics.events.map((e) => e.event),
      contains(AnalyticsEvent.searchSuccess),
    );
  });

  test('failed search emits searchFailure', () async {
    final container = await buildContainer(_FailRepo());
    container.read(searchQueryTextProvider.notifier).set('boom');
    container.read(searchQueryStateProvider.notifier).onQueryChanged('boom');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(container.read(searchQueryStateProvider), isA<SearchQueryError>());
    expect(
      analytics.events.map((e) => e.event),
      contains(AnalyticsEvent.searchFailure),
    );
  });
}

class _BaseRepo implements SearchRepository {
  @override
  Future<List<SearchPlace>> getRecentSearches() async => const [];
  @override
  Future<void> addRecentSearch(SearchPlace place) async {}
  @override
  Future<void> removeRecentSearch(String placeId) async {}
  @override
  Future<void> clearRecentSearches() async {}
  @override
  Future<SearchPlace?> getSavedPlace(SavedPlaceKind kind) async => null;
  @override
  Future<void> setSavedPlace(SavedPlaceKind kind, SearchPlace? place) async {}
  @override
  Future<List<SearchPlace>> getFavorites() async => const [];
  @override
  Future<void> addFavorite(SearchPlace place) async {}
  @override
  Future<void> removeFavorite(String placeId) async {}
  @override
  Future<bool> isFavorite(String placeId) async => false;
  @override
  Future<List<SearchPlace>> search(String query) async => const [];
}

class _OkRepo extends _BaseRepo {
  @override
  Future<List<SearchPlace>> search(String query) async => const [
        SearchPlace(
          id: 'p1',
          name: 'Dubai Mall',
          address: 'Downtown',
          latitude: 25.1972,
          longitude: 55.2796,
        ),
      ];
}

class _FailRepo extends _BaseRepo {
  @override
  Future<List<SearchPlace>> search(String query) async =>
      throw Exception('network down');
}
