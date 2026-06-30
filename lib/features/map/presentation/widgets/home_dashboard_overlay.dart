import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_gradient_orb.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_selectors.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/ui/rihla_floating_card.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';
import 'package:rihla/shared/ui/rihla_shortcut_chip.dart';

/// Idle "AI Home Dashboard" content shown on the full-screen map.
class HomeDashboardOverlay extends ConsumerWidget {
  const HomeDashboardOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNavigating = ref.watch(navigationIsActiveProvider);
    final journey = ref.watch(journeyControllerProvider);
    final exploreActive = ref.watch(exploreActiveProvider);
    final emergencyActive = ref.watch(emergencyActiveProvider);

    final isHome = !isNavigating &&
        journey is JourneyIdle &&
        !exploreActive &&
        !emergencyActive;

    ref.listen(journeyControllerProvider, (previous, next) {
      // Log the moment the home dashboard yields to the journey/route flow.
      if (previous is JourneyIdle && next is! JourneyIdle) {
        ref.read(appLoggerProvider).log(
              'home_overlay_hidden',
              category: ObservabilityCategory.navigation,
              data: {'journey_state': next.runtimeType.toString()},
            );
      }
    });

    final mediaQuery = MediaQuery.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: !isHome
          ? const SizedBox.shrink()
          : Stack(
              key: const ValueKey('home_dashboard'),
              children: [
                Positioned(
                  top: mediaQuery.padding.top + 76,
                  left: 16,
                  right: 16,
                  child: const _EntranceAnimation(
                    fromTop: true,
                    child: _HomeShortcutsRow(),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: mediaQuery.padding.top + 140,
                  child: const _EntranceAnimation(
                    delayMs: 80,
                    fromTop: true,
                    child: _MapQuickActions(),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 96 + mediaQuery.padding.bottom,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: const _EntranceAnimation(
                        delayMs: 120,
                        child: _AiJourneyCard(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Fade + slide + scale entrance for home dashboard elements.
class _EntranceAnimation extends StatefulWidget {
  const _EntranceAnimation({
    required this.child,
    this.delayMs = 0,
    this.fromTop = false,
  });

  final Widget child;
  final int delayMs;
  final bool fromTop;

  @override
  State<_EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<_EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 420 + widget.delayMs),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = 420 + widget.delayMs;
    final start = widget.delayMs / total;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    final beginOffset = widget.fromTop ? const Offset(0, -0.12) : const Offset(0, 0.18);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: widget.child,
        ),
      ),
    );
  }
}

class _HomeShortcutsRow extends ConsumerWidget {
  const _HomeShortcutsRow();

  void _select(WidgetRef ref, SearchPlace place) {
    ref.read(searchSelectionProvider).select(place);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(searchHomeProvider).value;
    final work = ref.watch(searchWorkProvider).value;
    final favorites = ref.watch(searchFavoritesProvider).value ?? const [];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          RihlaShortcutChip(
            icon: Icons.home_rounded,
            label: home?.name ?? context.l10n.searchAddHome,
            highlighted: home != null,
            onTap: home != null
                ? () => _select(ref, home)
                : () => context.push(RoutePaths.search),
          ),
          const SizedBox(width: 10),
          RihlaShortcutChip(
            icon: Icons.work_rounded,
            label: work?.name ?? context.l10n.searchAddWork,
            highlighted: work != null,
            onTap: work != null
                ? () => _select(ref, work)
                : () => context.push(RoutePaths.search),
          ),
          for (final fav in favorites) ...[
            const SizedBox(width: 10),
            RihlaShortcutChip(
              icon: Icons.favorite_rounded,
              label: fav.name,
              highlighted: true,
              onTap: () => _select(ref, fav),
            ),
          ],
          if (favorites.isEmpty) ...[
            const SizedBox(width: 10),
            RihlaShortcutChip(
              icon: Icons.favorite_border_rounded,
              label: context.l10n.searchFavorites,
              onTap: () => context.push(RoutePaths.search),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapQuickActions extends StatelessWidget {
  const _MapQuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AiOrbAction(onTap: () => context.push(RoutePaths.aiHome)),
        const SizedBox(height: 10),
        _RoundAction(
          icon: Icons.traffic_outlined,
          onTap: () => context.push(RoutePaths.traffic),
        ),
        const SizedBox(height: 10),
        _RoundAction(
          icon: Icons.speed_outlined,
          onTap: () => context.push(RoutePaths.drive),
        ),
      ],
    );
  }
}

class _AiOrbAction extends StatelessWidget {
  const _AiOrbAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: RihlaReferenceTokens.floatingShadow(opacity: 0.18),
          ),
          child: const AiGradientOrb(size: 46),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

/// Waze-style idle home card with a single "Let's Go" action that opens search.
/// Shown only when no destination has been planned.
class _AiJourneyCard extends ConsumerWidget {
  const _AiJourneyCard();

  void _openSearch(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.push(RoutePaths.search);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final teal = RihlaReferenceTokens.mapTeal;
    final locationState = ref.watch(locationControllerProvider);
    final hasFix = locationState is LocationActive;
    final locationLabel =
        hasFix ? l10n.homeCurrentLocationLabel : l10n.homeLocatingLabel;

    return RihlaFloatingCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasFix
                      ? teal.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasFix
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  size: 18,
                  color: hasFix ? teal : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PressableScale(
            onTap: () => _openSearch(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [teal, teal.withValues(alpha: 0.82)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: teal.withValues(alpha: 0.34),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.homeLetsGo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic press-scale wrapper for premium tap feedback.
class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
