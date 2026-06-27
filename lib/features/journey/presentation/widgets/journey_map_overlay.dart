import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_card_sheet.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_error_overlay.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_loading_overlay.dart';

/// Map overlay that renders journey loading, error, and preview states.
class JourneyMapOverlay extends ConsumerWidget {
  const JourneyMapOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyState = ref.watch(journeyControllerProvider);

    ref.listen(journeyControllerProvider, (previous, next) {
      if (next is JourneyStarted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.journeyStartedMessage)),
        );
        ref.read(journeyControllerProvider.notifier).acknowledgeStarted();
      }
    });

    return switch (journeyState) {
      JourneyLoading() => const JourneyLoadingOverlay(),
      JourneyError() => JourneyErrorOverlay(
          onRetry: () =>
              ref.read(journeyControllerProvider.notifier).retry(),
          onCancel: () =>
              ref.read(journeyControllerProvider.notifier).cancel(),
        ),
      JourneyPreview(:final summary) => JourneyCardSheet(
          summary: summary,
          onStart: () =>
              ref.read(journeyControllerProvider.notifier).startJourney(),
          onCancel: () =>
              ref.read(journeyControllerProvider.notifier).cancel(),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
