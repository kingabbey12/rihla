import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/map/domain/models/map_view_status.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/map/presentation/widgets/map_debug_overlay.dart';
import 'package:rihla/features/map/presentation/widgets/map_empty_view.dart';
import 'package:rihla/features/map/presentation/widgets/map_error_view.dart';
import 'package:rihla/features/map/presentation/widgets/map_loading_view.dart';
import 'package:rihla/features/map/presentation/widgets/map_view.dart';

/// The production map experience: a full-screen map with overlay states.
class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  void _retry(WidgetRef ref) {
    ref.read(mapViewStatusProvider.notifier).set(const MapInitializing());
    ref.read(mapRecreateProvider.notifier).bump();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(mapViewStatusProvider);
    final locationUnavailable = ref.watch(mapLocationUnavailableProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: MapView()),
          if (status is MapInitializing)
            const Positioned.fill(child: MapLoadingView()),
          if (status is MapErrored)
            Positioned.fill(
              child: MapErrorView(onRetry: () => _retry(ref)),
            ),
          if (locationUnavailable && status is MapReady)
            Positioned(
              left: 24,
              right: 24,
              bottom: 100 + MediaQuery.paddingOf(context).bottom,
              child: MapEmptyView(
                onRetry: () {
                  ref.read(mapLocationUnavailableProvider.notifier).dismiss();
                  ref.read(mapLocationRetryProvider.notifier).request();
                },
                onDismiss: () {
                  ref.read(mapLocationUnavailableProvider.notifier).dismiss();
                },
              ),
            ),
          if (kDebugMode)
            Positioned(
              left: 12,
              top: MediaQuery.paddingOf(context).top + 12,
              child: const MapDebugOverlay(),
            ),
        ],
      ),
    );
  }
}
