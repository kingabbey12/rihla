import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/explore/domain/entities/explore_filter.dart';
import 'package:rihla/features/explore/domain/entities/explore_state.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';

/// Filter controls for Explore discovery.
class ExploreFiltersSheet extends ConsumerStatefulWidget {
  const ExploreFiltersSheet({super.key});

  @override
  ConsumerState<ExploreFiltersSheet> createState() =>
      _ExploreFiltersSheetState();
}

class _ExploreFiltersSheetState extends ConsumerState<ExploreFiltersSheet> {
  late double _distance;
  late double? _minRating;
  late bool _openNow;
  late bool _open24Hours;
  late bool _freeParking;
  late bool _paidParking;
  late bool _accessible;
  late bool _familyFriendly;

  @override
  void initState() {
    super.initState();
    final state = ref.read(exploreControllerProvider);
    final filter = switch (state) {
      ExploreReady(:final filter) => filter,
      ExplorePlaceSelected(:final previous) => previous.filter,
      _ => ExploreFilter.defaults,
    };
    _distance = filter.maxDistanceKm;
    _minRating = filter.minRating;
    _openNow = filter.openNow;
    _open24Hours = filter.open24Hours;
    _freeParking = filter.freeParking;
    _paidParking = filter.paidParking;
    _accessible = filter.accessible;
    _familyFriendly = filter.familyFriendly;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filters', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Max distance: ${_distance.toStringAsFixed(0)} km'),
          Slider(
            value: _distance,
            min: 1,
            max: 50,
            divisions: 49,
            onChanged: (v) => setState(() => _distance = v),
          ),
          SwitchListTile(
            title: const Text('Open now'),
            value: _openNow,
            onChanged: (v) => setState(() => _openNow = v),
          ),
          SwitchListTile(
            title: const Text('24 hours'),
            value: _open24Hours,
            onChanged: (v) => setState(() => _open24Hours = v),
          ),
          SwitchListTile(
            title: const Text('Free parking'),
            value: _freeParking,
            onChanged: (v) => setState(() => _freeParking = v),
          ),
          SwitchListTile(
            title: const Text('Paid parking'),
            value: _paidParking,
            onChanged: (v) => setState(() => _paidParking = v),
          ),
          SwitchListTile(
            title: const Text('Accessible'),
            value: _accessible,
            onChanged: (v) => setState(() => _accessible = v),
          ),
          SwitchListTile(
            title: const Text('Family friendly'),
            value: _familyFriendly,
            onChanged: (v) => setState(() => _familyFriendly = v),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              await ref.read(exploreControllerProvider.notifier).applyFilter(
                    ExploreFilter(
                      maxDistanceKm: _distance,
                      minRating: _minRating,
                      openNow: _openNow,
                      open24Hours: _open24Hours,
                      freeParking: _freeParking,
                      paidParking: _paidParking,
                      accessible: _accessible,
                      familyFriendly: _familyFriendly,
                    ),
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Apply filters'),
          ),
        ],
      ),
    );
  }
}
