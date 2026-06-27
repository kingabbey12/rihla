import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/offline/domain/entities/offline_engine_state.dart';
import 'package:rihla/features/emergency/presentation/coordinators/emergency_coordinator.dart';
import 'package:rihla/features/offline/presentation/coordinators/offline_coordinator.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';

/// Starts the offline coordinator and network monitor at app launch.
class OfflineBootstrap extends ConsumerStatefulWidget {
  const OfflineBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<OfflineBootstrap> createState() => _OfflineBootstrapState();
}

class _OfflineBootstrapState extends ConsumerState<OfflineBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(offlineCoordinatorProvider).attach();
      ref.read(emergencyCoordinatorProvider).attach();
      ref.read(offlineControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final engineState = ref.watch(offlineEngineStateProvider);
    final isOffline = ref.watch(isOfflineModeProvider);

    return Stack(
      children: [
        widget.child,
        if (isOffline && engineState == OfflineEngineState.offline)
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.paddingOf(context).top,
            child: const _OfflineBanner(),
          ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade800,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Offline mode — using downloaded maps',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final offlineCoordinatorProvider = Provider<OfflineCoordinator>((ref) {
  final coordinator = OfflineCoordinator(ref);
  ref.onDispose(coordinator.detach);
  return coordinator;
});
