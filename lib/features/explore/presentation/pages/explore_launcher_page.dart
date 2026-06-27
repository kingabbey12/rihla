import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/routes/route_paths.dart';

/// Activates Explore and redirects to the map experience.
class ExploreLauncherPage extends ConsumerStatefulWidget {
  const ExploreLauncherPage({super.key});

  @override
  ConsumerState<ExploreLauncherPage> createState() =>
      _ExploreLauncherPageState();
}

class _ExploreLauncherPageState extends ConsumerState<ExploreLauncherPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(exploreControllerProvider.notifier).activate();
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
