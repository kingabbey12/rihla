import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/constants/app_constants.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/routes/route_paths.dart';

/// Floating search entry point shown on the map.
class MapSearchBar extends StatelessWidget {
  const MapSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Material(
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          color: context.colorScheme.surface,
          child: InkWell(
            onTap: () => context.push(RoutePaths.search),
            borderRadius:
                BorderRadius.circular(AppConstants.defaultBorderRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 22,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.searchWhereTo,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
