import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/features/launch/presentation/providers/permission_flow_provider.dart';
import 'package:rihla/features/launch/presentation/widgets/permission_request_screen.dart';
import 'package:rihla/routes/route_paths.dart';

/// Sequential permission flow driven by [PermissionRequestModel] registry.
class PermissionFlowPage extends ConsumerWidget {
  const PermissionFlowPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(permissionRequestsProvider);
    final currentIndex = ref.watch(permissionFlowIndexProvider);

    if (currentIndex >= requests.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(RoutePaths.authentication);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final model = requests[currentIndex];

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: PermissionRequestScreen(
            key: ValueKey(model.id),
            model: model,
            onAllow: () async {
              await requestSystemPermission(model.permission);
              ref.read(permissionFlowIndexProvider.notifier).advance();
            },
            onNotNow: () async {
              ref.read(permissionFlowIndexProvider.notifier).advance();
            },
          ),
        ),
      ),
    );
  }
}
