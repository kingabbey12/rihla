import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/accessibility/a11y.dart';
import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback_type.dart';
import 'package:rihla/features/beta_feedback/domain/models/beta_feedback_state.dart';
import 'package:rihla/features/beta_feedback/presentation/providers/beta_feedback_providers.dart';

/// Lightweight in-app beta feedback flow.
class BetaFeedbackPage extends ConsumerStatefulWidget {
  const BetaFeedbackPage({super.key, this.initialType});

  final BetaFeedbackType? initialType;

  @override
  ConsumerState<BetaFeedbackPage> createState() => _BetaFeedbackPageState();
}

class _BetaFeedbackPageState extends ConsumerState<BetaFeedbackPage> {
  late BetaFeedbackType _type;
  final _messageController = TextEditingController();
  int? _rating;
  bool _includeDiagnostics = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? BetaFeedbackType.bugReport;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(betaFeedbackControllerProvider);

    ref.listen(betaFeedbackControllerProvider, (_, next) {
      if (next is BetaFeedbackSubmitted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you — feedback saved for sync.')),
        );
        ref.read(betaFeedbackControllerProvider.notifier).reset();
        Navigator.pop(context);
      } else if (next is BetaFeedbackError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });

    final submitting = state is BetaFeedbackSubmitting;
    final showRating = _type == BetaFeedbackType.journeyFeedback;

    return Scaffold(
      appBar: AppBar(title: const Text('Beta Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Help us improve Rihla during the UAE closed beta.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          DropdownButtonFormField<BetaFeedbackType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Feedback type'),
            items: BetaFeedbackType.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.displayName),
                  ),
                )
                .toList(),
            onChanged: submitting
                ? null
                : (v) => setState(() => _type = v ?? _type),
          ),
          if (showRating) ...[
            const SizedBox(height: 16),
            Text('Journey rating', style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: List.generate(
                5,
                (i) => AccessibleIconButton(
                  icon: i < (_rating ?? 0) ? Icons.star : Icons.star_border,
                  label: 'Rate ${i + 1} stars',
                  color: Colors.amber,
                  onPressed: submitting ? null : () => setState(() => _rating = i + 1),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            enabled: !submitting,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Describe the issue or suggestion',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Attach diagnostic logs'),
            subtitle: const Text(
              'Includes app version, device info, and sanitized logs. '
              'No personal data unless you include it in the message.',
            ),
            value: _includeDiagnostics,
            onChanged: submitting
                ? null
                : (v) => setState(() => _includeDiagnostics = v),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: submitting || _messageController.text.trim().isEmpty
                ? null
                : () => ref.read(betaFeedbackControllerProvider.notifier).submit(
                      type: _type,
                      message: _messageController.text,
                      rating: _rating,
                      includeDiagnostics: _includeDiagnostics,
                    ),
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(submitting ? 'Sending…' : 'Send feedback'),
          ),
        ],
      ),
    );
  }
}
