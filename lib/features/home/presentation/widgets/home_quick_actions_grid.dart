import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/home/presentation/widgets/home_dashboard_entrance.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/design/rihla_glass.dart';
import 'package:rihla/shared/design/rihla_radii.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

class HomeQuickActionsGrid extends ConsumerWidget {
  const HomeQuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final actions = [
      _QuickAction(
        icon: Icons.local_gas_station_rounded,
        label: l10n.homeQuickFuel,
        color: const Color(0xFFF59E0B),
        onTap: () => _openExplore(ref, ExploreCategory.fuelStation),
      ),
      _QuickAction(
        icon: Icons.ev_station_rounded,
        label: l10n.homeQuickEv,
        color: const Color(0xFF10B981),
        onTap: () => _openExplore(ref, ExploreCategory.evCharger),
      ),
      _QuickAction(
        icon: Icons.restaurant_rounded,
        label: l10n.homeQuickRestaurants,
        color: const Color(0xFFEF4444),
        onTap: () => _openExplore(ref, ExploreCategory.restaurant),
      ),
      _QuickAction(
        icon: Icons.local_hospital_rounded,
        label: l10n.homeQuickHospitals,
        color: const Color(0xFF3B82F6),
        onTap: () => _openExplore(ref, ExploreCategory.hospital),
      ),
      _QuickAction(
        icon: Icons.wc_rounded,
        label: l10n.homeQuickRestrooms,
        color: const Color(0xFF8B5CF6),
        onTap: () => _openExplore(ref, ExploreCategory.restroom),
      ),
      _QuickAction(
        icon: Icons.report_rounded,
        label: l10n.homeQuickHazard,
        color: const Color(0xFFF97316),
        onTap: () => context.push(RoutePaths.reportIncident),
      ),
      _QuickAction(
        icon: Icons.sos_rounded,
        label: l10n.homeQuickSos,
        color: RihlaReferenceTokens.emergencyRed,
        onTap: () => context.push(RoutePaths.emergencyDashboard),
      ),
      _QuickAction(
        icon: Icons.auto_awesome_rounded,
        label: l10n.homeQuickAi,
        color: RihlaReferenceTokens.mapTeal,
        onTap: () => context.push(RoutePaths.aiHome),
      ),
    ];

    return HomeDashboardEntrance(
      delayMs: 240,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          final action = actions[index];
          return HomeDashboardEntrance(
            delayMs: 260 + index * 20,
            child: _QuickActionTile(action: action),
          );
        },
      ),
    );
  }

  Future<void> _openExplore(WidgetRef ref, ExploreCategory category) async {
    ref.read(emergencyControllerProvider.notifier).deactivate();
    await ref.read(exploreControllerProvider.notifier).activate(
          initialCategory: category,
        );
    ref.read(exploreControllerProvider.notifier).selectCategory(category);
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HomePressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
        action.onTap();
      },
      child: RihlaGlassSurface(
        borderRadius: RihlaRadii.cardAll,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shadow: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.14),
                borderRadius: RihlaRadii.mdAll,
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
