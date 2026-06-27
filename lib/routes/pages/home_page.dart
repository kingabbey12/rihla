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
        child: FilledButton.icon(
          onPressed: () => context.push(RoutePaths.offlineCenter),
          icon: const Icon(Icons.download_for_offline),
          label: const Text('Offline Center'),
        ),
      ),
    );
  }
}
