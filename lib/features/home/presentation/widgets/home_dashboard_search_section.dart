import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/home/presentation/widgets/home_dashboard_entrance.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/design/rihla_glass.dart';
import 'package:rihla/shared/design/rihla_radii.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

class HomeDashboardSearchSection extends ConsumerWidget {
  const HomeDashboardSearchSection({super.key});

  void _openSearch(BuildContext context) => context.push(RoutePaths.search);

  void _select(WidgetRef ref, SearchPlace place) {
    ref.read(searchSelectionProvider).select(place);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final home = ref.watch(searchHomeProvider).value;
    final work = ref.watch(searchWorkProvider).value;
    final recents = ref.watch(searchRecentsProvider).value ?? const [];

    return HomeDashboardEntrance(
      delayMs: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomePressableScale(
            onTap: () => _openSearch(context),
            child: RihlaGlassSurface(
              borderRadius: RihlaRadii.cardAll,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.homeSearchPlaceholder,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.mic_rounded,
                    color: RihlaReferenceTokens.mapTeal,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _ShortcutCard(
                  icon: Icons.home_rounded,
                  label: home?.name ?? l10n.searchHome,
                  subtitle: home?.address,
                  highlighted: home != null,
                  delayMs: 60,
                  onTap: home != null
                      ? () => _select(ref, home)
                      : () => _openSearch(context),
                ),
                const SizedBox(width: 10),
                _ShortcutCard(
                  icon: Icons.work_rounded,
                  label: work?.name ?? l10n.searchWork,
                  subtitle: work?.address,
                  highlighted: work != null,
                  delayMs: 90,
                  onTap: work != null
                      ? () => _select(ref, work)
                      : () => _openSearch(context),
                ),
                if (recents.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  _ShortcutCard(
                    icon: Icons.history_rounded,
                    label: l10n.homeRecentPlaces,
                    subtitle: recents.first.name,
                    highlighted: true,
                    delayMs: 120,
                    onTap: () => _select(ref, recents.first),
                  ),
                  for (final place in recents.skip(1).take(4)) ...[
                    const SizedBox(width: 10),
                    _ShortcutCard(
                      icon: Icons.place_rounded,
                      label: place.name,
                      subtitle: place.address,
                      highlighted: true,
                      delayMs: 140,
                      onTap: () => _select(ref, place),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.highlighted = false,
    this.delayMs = 0,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool highlighted;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teal = RihlaReferenceTokens.mapTeal;

    return HomeDashboardEntrance(
      delayMs: delayMs,
      child: HomePressableScale(
        onTap: onTap,
        child: RihlaGlassSurface(
          borderRadius: RihlaRadii.cardAll,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shadow: false,
          child: SizedBox(
            width: 132,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? teal.withValues(alpha: 0.14)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                    borderRadius: RihlaRadii.mdAll,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: highlighted ? teal : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
