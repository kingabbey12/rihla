import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/presentation/widgets/search_result_tile.dart';
import 'package:rihla/features/search/presentation/widgets/search_section_header.dart';

/// Recent search history list.
class SearchRecentSection extends StatelessWidget {
  const SearchRecentSection({
    required this.recents,
    required this.onPlaceTap,
    required this.onClear,
    super.key,
  });

  final List<SearchPlace> recents;
  final ValueChanged<SearchPlace> onPlaceTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (recents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchSectionHeader(
          title: context.l10n.searchRecentTitle,
          actionLabel: context.l10n.searchClearRecent,
          onAction: onClear,
        ),
        ...recents.map(
          (place) => SearchResultTile(
            place: place,
            leadingIcon: Icons.history,
            onTap: () => onPlaceTap(place),
          ),
        ),
      ],
    );
  }
}
