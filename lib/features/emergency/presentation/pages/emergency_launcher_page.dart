import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/routes/route_paths.dart';

/// Activates Emergency mode and redirects to the map.
class EmergencyLauncherPage extends ConsumerStatefulWidget {
  const EmergencyLauncherPage({super.key});

  @override
  ConsumerState<EmergencyLauncherPage> createState() =>
      _EmergencyLauncherPageState();
}

class _EmergencyLauncherPageState extends ConsumerState<EmergencyLauncherPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(emergencyControllerProvider.notifier).activate();
      if (mounted) context.go(RoutePaths.maps);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
