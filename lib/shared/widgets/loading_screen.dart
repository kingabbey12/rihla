import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/shared/design/rihla_design.dart';
import 'package:rihla/shared/widgets/rihla_skeleton.dart';

/// Full-screen loading state. Shows skeleton placeholders that hint at the
/// content shape plus a contextual message instead of a bare spinner.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ?? context.l10n.loadingMessage;

    return Scaffold(
      body: SafeArea(
        child: RihlaContentWidth(
          child: Padding(
            padding: const EdgeInsets.all(RihlaSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const RihlaSkeleton(width: 200, height: 26),
                const SizedBox(height: RihlaSpacing.xl),
                const RihlaSkeletonList(itemCount: 4),
                const SizedBox(height: RihlaSpacing.xl),
                Center(
                  child: Text(
                    displayMessage,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
