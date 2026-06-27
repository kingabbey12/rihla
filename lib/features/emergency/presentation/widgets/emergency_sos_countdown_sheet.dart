import 'package:flutter/material.dart';

/// Full-screen SOS countdown with cancel option.
class EmergencySosCountdownSheet extends StatelessWidget {
  const EmergencySosCountdownSheet({
    required this.secondsRemaining,
    required this.onCancel,
    super.key,
  });

  final int secondsRemaining;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sending SOS in',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$secondsRemaining',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onCancel,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
