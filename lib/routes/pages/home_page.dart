import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/routes/route_paths.dart';

/// Blank home screen — the application entry point.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.homeTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => context.push(RoutePaths.emergency),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              icon: const Icon(Icons.sos),
              label: const Text('Emergency'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push(RoutePaths.offlineCenter),
              icon: const Icon(Icons.download_for_offline),
              label: const Text('Offline Center'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push(RoutePaths.settings),
              icon: const Icon(Icons.cloud),
              label: const Text('Cloud & Account'),
            ),
          ],
        ),
      ),
    );
  }
}
