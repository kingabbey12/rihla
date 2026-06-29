import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/shared/widgets/empty_screen.dart';

/// Driving score screen — populated from real trip telemetry when available.
class RihlaDrivePage extends StatelessWidget {
  const RihlaDrivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rihla Drive'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const EmptyScreen(
        title: 'No driving score yet',
        message:
            'Complete journeys with Rihla to build your driving score from real trip data.',
        icon: Icons.speed_outlined,
      ),
    );
  }
}
