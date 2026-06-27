import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_filter.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';

/// Explore controller state.
sealed class ExploreState {
  const ExploreState();
}

class ExploreIdle extends ExploreState {
  const ExploreIdle();
}

class ExploreLoading extends ExploreState {
  const ExploreLoading({this.category});

  final ExploreCategory? category;
}

class ExploreReady extends ExploreState {
  const ExploreReady({
    required this.places,
    required this.category,
    required this.filter,
    required this.totalCount,
    required this.hasMore,
    this.isOffline = false,
    this.zoom = 12,
  });

  final List<ExplorePlace> places;
  final ExploreCategory? category;
  final ExploreFilter filter;
  final int totalCount;
  final bool hasMore;
  final bool isOffline;
  final double zoom;
}

class ExplorePlaceSelected extends ExploreState {
  const ExplorePlaceSelected({
    required this.place,
    required this.previous,
  });

  final ExplorePlace place;
  final ExploreReady previous;
}

class ExploreError extends ExploreState {
  const ExploreError({required this.message, this.previous});

  final String message;
  final ExploreState? previous;
}
