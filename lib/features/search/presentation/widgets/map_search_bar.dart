import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/design/rihla_design.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Floating glass search entry point shown on the map: hamburger menu,
/// "Where to?" prompt, and voice search. Subtly scales/elevates on press.
///
/// Layout:  ☰      Where to?                        🎤
class MapSearchBar extends StatefulWidget {
  const MapSearchBar({super.key});

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  bool _pressed = false;

  void _openSearch() => context.push(RoutePaths.search);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Translucent surface so the map shows through the glass effect.
    final glassColor = scheme.surface.withValues(alpha: isDark ? 0.74 : 0.82);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AnimatedScale(
              scale: _pressed ? 0.98 : 1,
              duration: RihlaMotion.fast,
              curve: RihlaMotion.standard,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: RihlaReferenceTokens.floatingShadow(
                    opacity: _pressed ? 0.10 : 0.18,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: RihlaGlass.blurSigma,
                      sigmaY: RihlaGlass.blurSigma,
                    ),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: glassColor,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.08 : 0.5,
                          ),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openSearch,
                          onHighlightChanged: (v) =>
                              setState(() => _pressed = v),
                          borderRadius: BorderRadius.circular(26),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.menu_rounded),
                                  tooltip: l10n.homeMenuLabel,
                                  color: scheme.onSurfaceVariant,
                                  onPressed: () =>
                                      context.push(RoutePaths.profile),
                                ),
                                Expanded(
                                  child: Text(
                                    l10n.searchWhereTo,
                                    style: context.textTheme.bodyLarge?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.auto_awesome_rounded),
                                  tooltip: l10n.searchVoiceLabel,
                                  color: scheme.primary,
                                  onPressed: () =>
                                      context.push(RoutePaths.aiHome),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
