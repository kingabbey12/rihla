import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_filter.dart';

/// Search parameters for Explore discovery.
class ExploreSearch {
  const ExploreSearch({
    this.query,
    this.category,
    this.filter = ExploreFilter.defaults,
    this.latitude,
    this.longitude,
    this.viewportNorth,
    this.viewportSouth,
    this.viewportEast,
    this.viewportWest,
    this.page = 0,
    this.pageSize = 50,
  });

  final String? query;
  final ExploreCategory? category;
  final ExploreFilter filter;
  final double? latitude;
  final double? longitude;
  final double? viewportNorth;
  final double? viewportSouth;
  final double? viewportEast;
  final double? viewportWest;
  final int page;
  final int pageSize;

  ExploreSearch copyWith({
    String? query,
    ExploreCategory? category,
    ExploreFilter? filter,
    double? latitude,
    double? longitude,
    double? viewportNorth,
    double? viewportSouth,
    double? viewportEast,
    double? viewportWest,
    int? page,
    int? pageSize,
  }) =>
      ExploreSearch(
        query: query ?? this.query,
        category: category ?? this.category,
        filter: filter ?? this.filter,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        viewportNorth: viewportNorth ?? this.viewportNorth,
        viewportSouth: viewportSouth ?? this.viewportSouth,
        viewportEast: viewportEast ?? this.viewportEast,
        viewportWest: viewportWest ?? this.viewportWest,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );
}
