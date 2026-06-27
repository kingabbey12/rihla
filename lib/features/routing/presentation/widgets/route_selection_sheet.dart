import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/presentation/widgets/route_option_card.dart';
import 'package:rihla/shared/widgets/premium_buttons.dart';

/// Bottom sheet for choosing among route alternatives.
class RouteSelectionSheet extends StatelessWidget {
  const RouteSelectionSheet({
    required this.result,
    required this.selectedRouteId,
    required this.onSelect,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final RouteResult result;
  final String? selectedRouteId;
  final ValueChanged<String> onSelect;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
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
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.routeChooseTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.routeChooseSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  itemCount: result.routes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final route = result.routes[index];
                    return RouteOptionCard(
                      route: route,
                      selected: route.id == selectedRouteId,
                      onTap: () => onSelect(route.id),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    PremiumPrimaryButton(
                      label: context.l10n.routeConfirm,
                      onPressed: selectedRouteId != null ? onConfirm : () {},
                    ),
                    const SizedBox(height: 8),
                    PremiumSecondaryButton(
                      label: context.l10n.routeCancel,
                      onPressed: onCancel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
