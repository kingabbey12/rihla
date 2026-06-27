import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/search/domain/entities/saved_place_kind.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/models/search_query_state.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/features/search/presentation/widgets/search_bar_field.dart';
import 'package:rihla/features/search/presentation/widgets/search_empty_view.dart';
import 'package:rihla/features/search/presentation/widgets/search_error_view.dart';
import 'package:rihla/features/search/presentation/widgets/search_loading_view.dart';
import 'package:rihla/features/search/presentation/widgets/search_recent_section.dart';
import 'package:rihla/features/search/presentation/widgets/search_result_tile.dart';
import 'package:rihla/features/search/presentation/widgets/search_saved_places_section.dart';
import 'package:rihla/features/search/presentation/widgets/search_section_header.dart';

/// Full-screen premium search experience with mock data.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    ref.read(searchQueryTextProvider.notifier).set(value);
    ref.read(searchQueryStateProvider.notifier).onQueryChanged(value);
    setState(() {});
  }

  void _clearQuery() {
    _controller.clear();
    ref.read(searchQueryTextProvider.notifier).clear();
    ref.read(searchQueryStateProvider.notifier).reset();
    setState(() {});
  }

  Future<void> _selectPlace(SearchPlace place, {bool popToMap = true}) async {
    await ref.read(searchSelectionProvider).select(place);
    if (!mounted) return;
    if (popToMap && context.canPop()) {
      context.pop();
    }
  }

  Future<void> _showPlaceActions(SearchPlace place) async {
    final repo = ref.read(searchRepositoryProvider);
    final isFavorite = await repo.isFavorite(place.id);
    if (!mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(context.l10n.searchOpenMap),
              onTap: () => Navigator.pop(context, 'map'),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(context.l10n.searchSetAsHome),
              onTap: () => Navigator.pop(context, 'home'),
            ),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: Text(context.l10n.searchSetAsWork),
              onTap: () => Navigator.pop(context, 'work'),
            ),
            ListTile(
              leading: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              title: Text(
                isFavorite
                    ? context.l10n.searchRemoveFromFavorites
                    : context.l10n.searchAddToFavorites,
              ),
              onTap: () => Navigator.pop(context, 'favorite'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'map':
        await _selectPlace(place);
      case 'home':
        await ref.read(searchHomeProvider.notifier).set(place);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.searchSetAsHome)),
          );
        }
      case 'work':
        await ref.read(searchWorkProvider.notifier).set(place);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.searchSetAsWork)),
          );
        }
      case 'favorite':
        await ref.read(searchFavoritesProvider.notifier).toggle(place);
    }
  }

  void _promptSetShortcut(SavedPlaceKind kind) {
    final message = switch (kind) {
      SavedPlaceKind.home => context.l10n.searchAddHome,
      SavedPlaceKind.work => context.l10n.searchAddWork,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final queryState = ref.watch(searchQueryStateProvider);
    final recents = ref.watch(searchRecentsProvider).value ?? [];
    final home = ref.watch(searchHomeProvider).value;
    final work = ref.watch(searchWorkProvider).value;
    final favorites = ref.watch(searchFavoritesProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.searchTitle),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBarField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onQueryChanged,
              onClear: _clearQuery,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildBody(
                queryState,
                recents: recents,
                home: home,
                work: work,
                favorites: favorites,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    SearchQueryState queryState, {
    required List<SearchPlace> recents,
    required SearchPlace? home,
    required SearchPlace? work,
    required List<SearchPlace> favorites,
  }) {
    return switch (queryState) {
      SearchQueryLoading() => const SearchLoadingView(),
      SearchQueryEmpty() => const SearchEmptyView(),
      SearchQueryError() => SearchErrorView(
          onRetry: () =>
              ref.read(searchQueryStateProvider.notifier).retry(),
        ),
      SearchQueryResults(:final places) => _ResultsList(
          places: places,
          onSelect: _selectPlace,
          onMore: _showPlaceActions,
        ),
      SearchQueryIdle() => ListView(
          children: [
            SearchSavedPlacesSection(
              home: home,
              work: work,
              favorites: favorites,
              onPlaceTap: (p) => _selectPlace(p),
              onAddHome: () => _promptSetShortcut(SavedPlaceKind.home),
              onAddWork: () => _promptSetShortcut(SavedPlaceKind.work),
            ),
            SearchRecentSection(
              recents: recents,
              onPlaceTap: (p) => _selectPlace(p),
              onClear: () =>
                  ref.read(searchRecentsProvider.notifier).clear(),
            ),
            _PopularSuggestions(onSelect: _selectPlace),
          ],
        ),
    };
  }
}

class _ResultsList extends ConsumerWidget {
  const _ResultsList({
    required this.places,
    required this.onSelect,
    required this.onMore,
  });

  final List<SearchPlace> places;
  final Future<void> Function(SearchPlace place) onSelect;
  final Future<void> Function(SearchPlace place) onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return SearchResultTile(
          place: place,
          onTap: () => onSelect(place),
          trailing: IconButton(
            icon: const Icon(Icons.more_horiz, size: 20),
            onPressed: () => onMore(place),
          ),
        );
      },
    );
  }
}

class _PopularSuggestions extends ConsumerWidget {
  const _PopularSuggestions({required this.onSelect});

  final Future<void> Function(SearchPlace place) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popular = ref.watch(_popularSuggestionsProvider);
    return popular.when(
      data: (places) {
        if (places.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchSectionHeader(title: context.l10n.searchSuggestionsTitle),
            ...places.map(
              (place) => SearchResultTile(
                place: place,
                onTap: () => onSelect(place),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

final _popularSuggestionsProvider = FutureProvider<List<SearchPlace>>((ref) {
  return ref.read(searchRepositoryProvider).search('');
});
