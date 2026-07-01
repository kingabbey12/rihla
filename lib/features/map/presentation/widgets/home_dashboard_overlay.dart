import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/features/home/presentation/providers/home_dashboard_providers.dart';
import 'package:rihla/features/home/presentation/widgets/home_dashboard_panel.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/shared/design/rihla_glass.dart';
import 'package:rihla/shared/design/rihla_radii.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Idle home dashboard overlay shown on the full-screen map.
class HomeDashboardOverlay extends ConsumerWidget {
  const HomeDashboardOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(homeDashboardVisibleProvider);
    final expanded = ref.watch(homeDashboardExpandedProvider);

    ref.listen(journeyControllerProvider, (previous, next) {
      if (previous is JourneyIdle && next is! JourneyIdle) {
        ref.read(appLoggerProvider).log(
              'home_overlay_hidden',
              category: ObservabilityCategory.navigation,
              data: {'journey_state': next.runtimeType.toString()},
            );
      }
    });

    if (!visible) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: expanded
          ? Stack(
              key: const ValueKey('home_dashboard'),
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.72),
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.35, 0.65],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: topInset,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: const HomeDashboardPanel(),
                ),
              ],
            )
          : Align(
              key: const ValueKey('home_dashboard_collapsed'),
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 88 + mediaQuery.padding.bottom,
                ),
                child: _CollapsedDashboardChip(
                  onTap: () {
                    ref.read(homeDashboardExpandedProvider.notifier).expand();
                  },
                ),
              ),
            ),
    );
  }
}

class _CollapsedDashboardChip extends StatelessWidget {
  const _CollapsedDashboardChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: RihlaGlassSurface(
        borderRadius: RihlaRadii.cardAll,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.dashboard_rounded,
              color: RihlaReferenceTokens.mapTeal,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.homeShowDashboard,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
