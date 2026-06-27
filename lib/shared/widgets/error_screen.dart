import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Full-screen error state with an optional retry action.
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final displayTitle = title ?? context.l10n.errorTitle;
    final displayMessage = message ?? context.l10n.errorMessage;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: context.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                displayTitle,
                style: context.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                displayMessage,
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.retryButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
