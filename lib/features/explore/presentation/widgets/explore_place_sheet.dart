import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
class ExplorePlaceSheet extends ConsumerWidget {
  const ExplorePlaceSheet({
    required this.place,
    required this.onDismiss,
    super.key,
  });

  final ExplorePlace place;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favorites = ref.watch(exploreFavoritesRepositoryProvider);
    final isSaved = favorites.isSaved(place.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (place.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    place.photoUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    cacheWidth: 800,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.place,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(place.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                place.category.displayName,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              if (place.rating != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: theme.colorScheme.tertiary, size: 20),
                    const SizedBox(width: 4),
                    Text('${place.rating!.toStringAsFixed(1)}'),
                    if (place.reviewCount != null)
                      Text(' (${place.reviewCount} reviews)'),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _InfoRow(icon: Icons.schedule, label: place.openingHours ?? '—'),
              if (place.distanceKm != null)
                _InfoRow(
                  icon: Icons.straighten,
                  label: '${place.distanceKm!.toStringAsFixed(1)} km away',
                ),
              if (place.etaMinutes != null)
                _InfoRow(
                  icon: Icons.directions_car,
                  label: '~${place.etaMinutes} min ETA',
                ),
              if (place.phone != null)
                _InfoRow(icon: Icons.phone, label: place.phone!),
              if (place.website != null)
                _InfoRow(icon: Icons.language, label: place.website!),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(journeyControllerProvider.notifier)
                            .planToDestination(place.toSearchPlace());
                        onDismiss();
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigate'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () async {
                      if (isSaved) {
                        await favorites.removeSavedPlace(place.id);
                      } else {
                        await favorites.savePlace(place);
                      }
                      ref.invalidate(exploreFavoritesRepositoryProvider);
                    },
                    icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      final link =
                          'https://maps.google.com/?q=${place.latitude},${place.longitude}';
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.share),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thanks — we will review this report.'),
                    ),
                  );
                },
                child: const Text('Report incorrect information'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
