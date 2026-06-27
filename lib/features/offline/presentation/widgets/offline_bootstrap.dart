import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/offline/domain/entities/offline_engine_state.dart';
import 'package:rihla/features/emergency/presentation/coordinators/emergency_coordinator.dart';
import 'package:rihla/features/account/presentation/coordinators/account_sync_coordinator.dart';
import 'package:rihla/features/offline/presentation/coordinators/offline_coordinator.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';

/// Starts the offline coordinator and network monitor at app launch.
///
/// This widget is mounted ABOVE [MaterialApp] (it wraps the root [App]), so it
/// must never build directional/visual UI here — there is no [Directionality],
/// [MediaQuery], [Theme], or [Localizations] above the app. It therefore only
/// runs startup side-effects and returns its child unchanged. The user-facing
/// offline banner is rendered by [OfflineBannerOverlay] from inside the
/// `MaterialApp.builder`, where those inherited widgets exist.
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
      ref.read(accountSyncCoordinatorProvider).attach();
      ref.read(offlineControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Top-of-screen offline banner. Designed to be placed inside the
/// `MaterialApp.builder` so it has access to [Directionality], [MediaQuery],
/// and [Theme]. Renders nothing unless the app is in offline mode.
class OfflineBannerOverlay extends ConsumerWidget {
  const OfflineBannerOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engineState = ref.watch(offlineEngineStateProvider);
    final isOffline = ref.watch(isOfflineModeProvider);
    final showBanner = isOffline && engineState == OfflineEngineState.offline;

    return Stack(
      textDirection: Directionality.of(context),
      children: [
        child,
        if (showBanner)
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
