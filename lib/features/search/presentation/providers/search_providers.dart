import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/search/data/datasources/search_local_datasource.dart';
import 'package:rihla/features/search/data/repositories/search_repository_impl.dart';
import 'package:rihla/features/search/data/services/mock_search_service.dart';
import 'package:rihla/features/search/domain/entities/saved_place_kind.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/errors/search_failure.dart';
import 'package:rihla/features/search/domain/models/search_query_state.dart';
import 'package:rihla/features/search/domain/repositories/search_repository.dart';
import 'package:rihla/features/search/domain/services/search_service.dart';

/// Provides the mock [SearchService].
final searchServiceProvider = Provider<SearchService>(
  (ref) => MockSearchService(),
);

/// Provides the local search data source.
final searchLocalDataSourceProvider = Provider<SearchLocalDataSource>(
  (ref) => SearchLocalDataSource(ref.watch(sharedPreferencesProvider)),
);

/// Provides the [SearchRepository] facade.
final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(
    ref.watch(searchServiceProvider),
    ref.watch(searchLocalDataSourceProvider),
  ),
);

/// Saved home shortcut (null when unset).
final searchHomeProvider =
    AsyncNotifierProvider<SearchHomeNotifier, SearchPlace?>(
  SearchHomeNotifier.new,
);

class SearchHomeNotifier extends AsyncNotifier<SearchPlace?> {
  @override
  Future<SearchPlace?> build() =>
      ref.read(searchRepositoryProvider).getSavedPlace(SavedPlaceKind.home);

  Future<void> set(SearchPlace? place) async {
    await ref
        .read(searchRepositoryProvider)
        .setSavedPlace(SavedPlaceKind.home, place);
    state = AsyncData(place);
  }
}

/// Saved work shortcut (null when unset).
final searchWorkProvider =
    AsyncNotifierProvider<SearchWorkNotifier, SearchPlace?>(
  SearchWorkNotifier.new,
);

class SearchWorkNotifier extends AsyncNotifier<SearchPlace?> {
  @override
  Future<SearchPlace?> build() =>
      ref.read(searchRepositoryProvider).getSavedPlace(SavedPlaceKind.work);

  Future<void> set(SearchPlace? place) async {
    await ref
        .read(searchRepositoryProvider)
        .setSavedPlace(SavedPlaceKind.work, place);
    state = AsyncData(place);
  }
}

/// User-curated favorite places.
final searchFavoritesProvider =
    AsyncNotifierProvider<SearchFavoritesNotifier, List<SearchPlace>>(
  SearchFavoritesNotifier.new,
);

class SearchFavoritesNotifier extends AsyncNotifier<List<SearchPlace>> {
  @override
  Future<List<SearchPlace>> build() =>
      ref.read(searchRepositoryProvider).getFavorites();

  Future<void> add(SearchPlace place) async {
    await ref.read(searchRepositoryProvider).addFavorite(place);
    state = AsyncData(await ref.read(searchRepositoryProvider).getFavorites());
  }

  Future<void> remove(String placeId) async {
    await ref.read(searchRepositoryProvider).removeFavorite(placeId);
    state = AsyncData(await ref.read(searchRepositoryProvider).getFavorites());
  }

  Future<void> toggle(SearchPlace place) async {
    final repo = ref.read(searchRepositoryProvider);
    if (await repo.isFavorite(place.id)) {
      await remove(place.id);
    } else {
      await add(place);
    }
  }
}

/// Recent search history.
final searchRecentsProvider =
    AsyncNotifierProvider<SearchRecentsNotifier, List<SearchPlace>>(
  SearchRecentsNotifier.new,
);

class SearchRecentsNotifier extends AsyncNotifier<List<SearchPlace>> {
  @override
  Future<List<SearchPlace>> build() =>
      ref.read(searchRepositoryProvider).getRecentSearches();

  Future<void> refresh() async {
    state = AsyncData(
      await ref.read(searchRepositoryProvider).getRecentSearches(),
    );
  }

  Future<void> clear() async {
    await ref.read(searchRepositoryProvider).clearRecentSearches();
    state = const AsyncData([]);
  }

  Future<void> remove(String placeId) async {
    await ref.read(searchRepositoryProvider).removeRecentSearch(placeId);
    await refresh();
  }
}

/// Active search query text.
final searchQueryTextProvider =
    NotifierProvider<SearchQueryTextNotifier, String>(
  SearchQueryTextNotifier.new,
);

class SearchQueryTextNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

/// Search results state machine.
final searchQueryStateProvider =
    NotifierProvider<SearchQueryStateNotifier, SearchQueryState>(
  SearchQueryStateNotifier.new,
);

class SearchQueryStateNotifier extends Notifier<SearchQueryState> {
  Timer? _debounce;

  @override
  SearchQueryState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchQueryIdle();
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      state = const SearchQueryIdle();
      return;
    }

    state = SearchQueryLoading(trimmed);
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(trimmed));
  }

  Future<void> _run(String query) async {
    try {
      final results = await ref.read(searchRepositoryProvider).search(query);
      if (ref.read(searchQueryTextProvider).trim() != query) return;

      state = results.isEmpty
          ? SearchQueryEmpty(query)
          : SearchQueryResults(query: query, places: results);
    } catch (e) {
      if (ref.read(searchQueryTextProvider).trim() != query) return;
      state = SearchQueryError(
        query: query,
        failure: SearchServiceFailure(e.toString()),
      );
    }
  }

  void reset() {
    _debounce?.cancel();
    state = const SearchQueryIdle();
  }

  void retry() {
    final query = ref.read(searchQueryTextProvider).trim();
    if (query.isNotEmpty) onQueryChanged(query);
  }
}

/// Selects a place: persists recents and opens the Journey Card on the map.
final searchSelectionProvider = Provider<SearchSelectionHandler>(
  (ref) => SearchSelectionHandler(ref),
);

class SearchSelectionHandler {
  SearchSelectionHandler(this._ref);

  final Ref _ref;

  Future<SearchPlace> select(SearchPlace place) async {
    final repo = _ref.read(searchRepositoryProvider);
    await repo.addRecentSearch(place);
    await _ref.read(searchRecentsProvider.notifier).refresh();

    await _ref.read(journeyControllerProvider.notifier).planToDestination(place);

    return place;
  }
}
