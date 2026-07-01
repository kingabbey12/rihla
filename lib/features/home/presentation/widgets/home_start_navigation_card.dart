import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/home/presentation/widgets/home_dashboard_entrance.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/design/rihla_radii.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

class HomeStartNavigationCard extends StatelessWidget {
  const HomeStartNavigationCard({super.key});

  void _openSearch(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.push(RoutePaths.search);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final teal = RihlaReferenceTokens.mapTeal;

    return HomeDashboardEntrance(
      delayMs: 160,
      child: HomePressableScale(
        onTap: () => _openSearch(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                teal,
                Color.lerp(teal, const Color(0xFF2563EB), 0.35)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: RihlaRadii.cardAll,
            boxShadow: [
              BoxShadow(
                color: teal.withValues(alpha: 0.38),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: RihlaRadii.lgAll,
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.homeStartNavigation,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
