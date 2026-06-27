import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Departure time suggestions for the journey.
class JourneyDepartureSuggestions extends StatelessWidget {
  const JourneyDepartureSuggestions({required this.suggestions, super.key});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.journeyDeparture,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...suggestions.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
