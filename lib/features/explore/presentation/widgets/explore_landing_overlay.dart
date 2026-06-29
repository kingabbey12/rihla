import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_category_card.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_recommendation_card.dart';

/// Premium Explore discovery landing shown before a category is chosen.
class ExploreLandingOverlay extends ConsumerStatefulWidget {
  const ExploreLandingOverlay({super.key});

  @override
  ConsumerState<ExploreLandingOverlay> createState() =>
      _ExploreLandingOverlayState();
}

class _ExploreLandingOverlayState extends ConsumerState<ExploreLandingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  int _columnsFor(double width) {
    if (width >= 1100) return 6;
    if (width >= 820) return 5;
    if (width >= 560) return 4;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final recommendations = ref.watch(exploreJourneyRecommendationsProvider);

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = _columnsFor(constraints.maxWidth);
            final maxContentWidth =
                constraints.maxWidth > 720 ? 720.0 : constraints.maxWidth;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                topPad + 64,
                20,
                110 + bottomPad,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Section(
                          controller: _controller,
                          order: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'What would you like to\ndiscover today?',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (recommendations
                            case AsyncData(:final value) when value.isNotEmpty)
                          _Section(
                            controller: _controller,
                            order: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeader(
                                  icon: Icons.auto_awesome,
                                  label: 'Recommended for you',
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 124,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    clipBehavior: Clip.none,
                                    itemCount: value.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, index) =>
                                        ExploreRecommendationCard(
                                      recommendation: value[index],
                                      onTap: (place) => ref
                                          .read(exploreControllerProvider
                                              .notifier)
                                          .selectPlace(place),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        _Section(
                          controller: _controller,
                          order: 2,
                          child: _SectionHeader(
                            icon: Icons.grid_view_rounded,
                            label: 'Browse categories',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Section(
                          controller: _controller,
                          order: 3,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.92,
                            ),
                            itemCount: ExploreCategory.values.length,
                            itemBuilder: (context, index) {
                              final category = ExploreCategory.values[index];
                              return ExploreCategoryCard(
                                category: category,
                                onTap: () => ref
                                    .read(exploreControllerProvider.notifier)
                                    .selectCategory(category),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Staggered fade + slide entrance for a landing section.
class _Section extends StatelessWidget {
  const _Section({
    required this.controller,
    required this.order,
    required this.child,
  });

  final AnimationController controller;
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (order * 0.12).clamp(0.0, 0.8);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
