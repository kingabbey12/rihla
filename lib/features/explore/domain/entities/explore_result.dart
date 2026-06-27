import 'package:rihla/features/explore/domain/entities/explore_place.dart';

/// Paginated Explore query result.
class ExploreResult {
  const ExploreResult({
    required this.places,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.isOffline = false,
  });

  final List<ExplorePlace> places;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isOffline;

  static const empty = ExploreResult(
    places: [],
    totalCount: 0,
    page: 0,
    pageSize: 50,
    hasMore: false,
  );
}
