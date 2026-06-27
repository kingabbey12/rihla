import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/app/coordinators/driving_session_coordinator.dart';
import 'package:rihla/app/providers/driving_session_ui_providers.dart';
import 'package:rihla/app/providers/map_session_providers.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Activates map session lifecycle and the driving session coordinator.
class MapSessionHost extends ConsumerStatefulWidget {
  const MapSessionHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<MapSessionHost> createState() => _MapSessionHostState();
}

class _MapSessionHostState extends ConsumerState<MapSessionHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mapSessionActiveProvider.notifier).setActive(true);
      }
    });
  }

  @override
  void dispose() {
    ref.read(mapSessionActiveProvider.notifier).setActive(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(drivingSessionCoordinatorProvider);
    return widget.child;
  }
}

/// Listens for coordinator UI events (snackbars, etc.) without side effects in build.
class DrivingSessionUiListener extends ConsumerWidget {
  const DrivingSessionUiListener({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(drivingSessionUiEventProvider, (previous, next) {
      if (next == DrivingSessionUiEvent.routeConfirmed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.routeConfirmedMessage)),
        );
        ref.read(drivingSessionUiEventProvider.notifier).clear();
      }
    });
    return const SizedBox.shrink();
  }
}
