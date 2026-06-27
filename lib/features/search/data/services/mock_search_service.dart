import 'package:rihla/features/search/data/datasources/mock_search_places_catalog.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/services/search_service.dart';

/// Offline search backed by the static mock catalog.
class MockSearchService implements SearchService {
  MockSearchService({
    this.simulatedDelay = const Duration(milliseconds: 350),
    this.shouldFail = false,
  });

  /// Artificial delay so loading states are visible during development.
  final Duration simulatedDelay;

  /// When true, every call throws to exercise error handling.
  final bool shouldFail;

  @override
  Future<List<SearchPlace>> suggest(String query) async {
    await Future<void>.delayed(simulatedDelay);
    if (shouldFail) {
      throw Exception('Mock search service failure');
    }

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return MockSearchPlacesCatalog.popular;
    }

    return MockSearchPlacesCatalog.all
        .where(
          (place) =>
              place.name.toLowerCase().contains(trimmed) ||
              place.address.toLowerCase().contains(trimmed) ||
              (place.category?.toLowerCase().contains(trimmed) ?? false),
        )
        .toList();
  }
}
