import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Floating map controls: zoom, orientation reset, and my-location.
///
/// Pure presentation — all actions are delegated via callbacks so the widget
/// stays testable without the native map.
class MapControls extends StatelessWidget {
  const MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
    required this.onMyLocation,
    this.myLocationActive = false,
    super.key,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;
  final VoidCallback onMyLocation;
  final bool myLocationActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlGroup(
          children: [
            _MapButton(
              icon: Icons.add,
              tooltip: context.l10n.mapZoomIn,
              onPressed: onZoomIn,
            ),
            const _ControlDivider(),
            _MapButton(
              icon: Icons.remove,
              tooltip: context.l10n.mapZoomOut,
              onPressed: onZoomOut,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ControlGroup(
          children: [
            _MapButton(
              icon: Icons.explore_outlined,
              tooltip: context.l10n.mapRecenter,
              onPressed: onRecenter,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ControlGroup(
          children: [
            _MapButton(
              icon: myLocationActive
                  ? Icons.my_location
                  : Icons.location_searching,
              tooltip: context.l10n.mapMyLocation,
              onPressed: onMyLocation,
              highlighted: myLocationActive,
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _ControlDivider extends StatelessWidget {
  const _ControlDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: 28,
      color: context.colorScheme.outlineVariant,
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color =
        highlighted ? context.colorScheme.primary : context.colorScheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 28,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}
