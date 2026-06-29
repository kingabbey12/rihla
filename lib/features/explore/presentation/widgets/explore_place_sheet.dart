import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/explore/presentation/extensions/explore_category_style.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';

/// Premium place details sheet with a hero header and glass actions.
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
      initialChildSize: 0.58,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                _Hero(place: place),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (place.rating != null) _RatingChip(place: place),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        place.category.displayName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: place.category.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StatusRow(place: place),
                      const SizedBox(height: 16),
                      _ContactRows(place: place),
                      const SizedBox(height: 20),
                      _Actions(
                        place: place,
                        isSaved: isSaved,
                        onNavigate: () async {
                          await ref
                              .read(journeyControllerProvider.notifier)
                              .planToDestination(place.toSearchPlace());
                          onDismiss();
                        },
                        onSaveToggle: () async {
                          if (isSaved) {
                            await favorites.removeSavedPlace(place.id);
                          } else {
                            await favorites.savePlace(place);
                          }
                          ref.invalidate(exploreFavoritesRepositoryProvider);
                        },
                        onShare: () {
                          final link =
                              'https://maps.google.com/?q=${place.latitude},${place.longitude}';
                          Clipboard.setData(ClipboardData(text: link));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link copied to clipboard'),
                            ),
                          );
                        },
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Thanks — we will review this report.'),
                              ),
                            );
                          },
                          child: const Text('Report incorrect information'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.place});

  final ExplorePlace place;

  @override
  Widget build(BuildContext context) {
    final gradient = place.category.gradient;
    final fallback = Container(
      height: 184,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          place.category.glyph,
          size: 72,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );

    final image = place.photoUrl == null
        ? fallback
        : Image.network(
            place.photoUrl!,
            height: 184,
            width: double.infinity,
            fit: BoxFit.cover,
            cacheWidth: 1000,
            errorBuilder: (_, _, _) => fallback,
          );

    return Stack(
      children: [
        SizedBox(width: double.infinity, child: image),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.place});

  final ExplorePlace place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: theme.colorScheme.tertiary, size: 18),
          const SizedBox(width: 4),
          Text(
            place.rating!.toStringAsFixed(1),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (place.reviewCount != null)
            Text(
              ' (${place.reviewCount})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.place});

  final ExplorePlace place;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (place.isOpenNow != null) {
      chips.add(_StatusChip(
        label: place.isOpenNow! ? 'Open now' : 'Closed',
        color: place.isOpenNow! ? const Color(0xFF159947) : const Color(0xFFE53935),
        icon: place.isOpenNow! ? Icons.check_circle_rounded : Icons.cancel_rounded,
      ));
    } else if (place.isOpen24Hours == true) {
      chips.add(const _StatusChip(
        label: 'Open 24h',
        color: Color(0xFF159947),
        icon: Icons.access_time_filled_rounded,
      ));
    }
    if (place.distanceKm != null) {
      chips.add(_InfoPill(
        icon: Icons.straighten_rounded,
        value: '${place.distanceKm!.toStringAsFixed(1)} km',
        label: 'Distance',
      ));
    }
    if (place.etaMinutes != null) {
      chips.add(_InfoPill(
        icon: Icons.directions_car_rounded,
        value: '${place.etaMinutes} min',
        label: 'Travel time',
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 10, runSpacing: 10, children: chips);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactRows extends StatelessWidget {
  const _ContactRows({required this.place});

  final ExplorePlace place;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (place.openingHours != null) {
      rows.add(_ContactRow(icon: Icons.schedule_rounded, label: place.openingHours!));
    }
    if (place.phone != null) {
      rows.add(_ContactRow(icon: Icons.phone_rounded, label: place.phone!));
    }
    if (place.website != null) {
      rows.add(_ContactRow(icon: Icons.language_rounded, label: place.website!));
    }
    rows.add(_ContactRow(icon: Icons.place_rounded, label: place.address));
    return Column(children: rows);
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.place,
    required this.isSaved,
    required this.onNavigate,
    required this.onSaveToggle,
    required this.onShare,
  });

  final ExplorePlace place;
  final bool isSaved;
  final VoidCallback onNavigate;
  final VoidCallback onSaveToggle;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final gradient = place.category.gradient;
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.last.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onNavigate,
              icon: const Icon(Icons.navigation_rounded),
              label: const Text(
                'Navigate',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _GlassAction(
          icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          active: isSaved,
          onTap: onSaveToggle,
        ),
        const SizedBox(width: 10),
        _GlassAction(icon: Icons.ios_share_rounded, onTap: onShare),
      ],
    );
  }
}

class _GlassAction extends StatelessWidget {
  const _GlassAction({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active ? theme.colorScheme.primary : theme.colorScheme.onSurface;
    return Material(
      color: active
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}
