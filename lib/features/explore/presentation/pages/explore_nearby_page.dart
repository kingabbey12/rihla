import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/explore/domain/entities/explore_state.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';
import 'package:rihla/shared/widgets/empty_screen.dart';
import 'package:rihla/theme/app_colors.dart';

/// Nearby places loaded from live explore APIs (fuel, EV, parking, OSM, etc.).
class ExploreNearbyPage extends ConsumerStatefulWidget {
  const ExploreNearbyPage({super.key});

  @override
  ConsumerState<ExploreNearbyPage> createState() => _ExploreNearbyPageState();
}

class _ExploreNearbyPageState extends ConsumerState<ExploreNearbyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exploreControllerProvider.notifier).activate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exploreState = ref.watch(exploreControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        title: const Text('Explore Nearby'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search nearby places',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: RihlaReferenceTokens.darkSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimaryDark),
            onSubmitted: (_) =>
                ref.read(exploreControllerProvider.notifier).refresh(),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (final cat in ExploreCategory.values.take(12))
                _CategoryTile(
                  category: cat,
                  onTap: () => ref
                      .read(exploreControllerProvider.notifier)
                      .selectCategory(cat),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Near You',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          switch (exploreState) {
            ExploreLoading() => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            ExploreError(:final message) => EmptyScreen(
                title: 'Could not load places',
                message: message,
                icon: Icons.wifi_off_rounded,
                actionLabel: 'Retry',
                onAction: () =>
                    ref.read(exploreControllerProvider.notifier).refresh(),
              ),
            ExploreReady(:final places) when places.isEmpty => const EmptyScreen(
                title: 'No places nearby',
                message: 'Try another category or move to a busier area.',
                icon: Icons.place_outlined,
              ),
            ExploreReady(:final places) => Column(
                children: [
                  for (final place in places.take(20))
                    _PlaceCard(place: place),
                ],
              ),
            _ => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
          },
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final ExploreCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RihlaReferenceTokens.darkSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconFor(category), color: RihlaReferenceTokens.mapTeal, size: 22),
            const SizedBox(height: 6),
            Text(
              category.displayName.split(' ').first,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ExploreCategory c) => switch (c) {
        ExploreCategory.fuelStation => Icons.local_gas_station,
        ExploreCategory.evCharger => Icons.ev_station,
        ExploreCategory.restaurant => Icons.restaurant,
        ExploreCategory.coffeeShop => Icons.coffee,
        ExploreCategory.hotel => Icons.hotel,
        ExploreCategory.parking => Icons.local_parking,
        ExploreCategory.hospital => Icons.local_hospital,
        ExploreCategory.pharmacy => Icons.local_pharmacy,
        ExploreCategory.mosque => Icons.mosque,
        ExploreCategory.atm => Icons.atm,
        ExploreCategory.shoppingMall => Icons.shopping_bag,
        _ => Icons.place,
      };
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place});

  final ExplorePlace place;

  @override
  Widget build(BuildContext context) {
    final distance = place.distanceKm != null
        ? '${place.distanceKm!.toStringAsFixed(1)} km'
        : '—';
    final rating = place.rating?.toStringAsFixed(1) ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RihlaReferenceTokens.darkSurface,
        borderRadius: BorderRadius.circular(RihlaReferenceTokens.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: RihlaReferenceTokens.mapTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.place, color: RihlaReferenceTokens.mapTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  place.address,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distance,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              if (place.rating != null)
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: RihlaReferenceTokens.goldAccent,
                    ),
                    Text(
                      rating,
                      style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
