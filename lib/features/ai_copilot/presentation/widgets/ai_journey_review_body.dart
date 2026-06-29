import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_recommendation.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_gradient_orb.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_recommendation_cards.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_score_ring.dart';
import 'package:rihla/features/ai_copilot/presentation/widgets/ai_streaming_text.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Presentation-only Journey Review content: scores, trip stats, AI insights,
/// and share/save actions. Driven by explicit values so it is easy to compose.
class AiJourneyReviewBody extends StatelessWidget {
  const AiJourneyReviewBody({
    required this.summary,
    required this.highlights,
    required this.recommendations,
    required this.journeyScore,
    required this.safetyScore,
    required this.drivingScore,
    required this.distanceKm,
    required this.durationMinutes,
    required this.fuelLiters,
    required this.onShare,
    required this.onSave,
    required this.onDone,
    super.key,
    this.scrollController,
    this.streamSummary = true,
  });

  final String summary;
  final List<String> highlights;
  final List<AiRecommendation> recommendations;
  final int journeyScore;
  final int safetyScore;
  final int drivingScore;
  final double distanceKm;
  final int durationMinutes;
  final double fuelLiters;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onDone;
  final ScrollController? scrollController;
  final bool streamSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const teal = RihlaReferenceTokens.mapTeal;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Row(
          children: [
            const AiGradientOrb(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Journey Review',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Here\'s how your trip went',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AiScoreRing(score: journeyScore, label: 'Trip', color: teal),
            AiScoreRing(
              score: safetyScore,
              label: 'Safety',
              color: const Color(0xFF2563EB),
            ),
            AiScoreRing(
              score: drivingScore,
              label: 'Driving',
              color: const Color(0xFF7C5CFF),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _Stat(
                icon: Icons.route_rounded,
                value: distanceKm.toStringAsFixed(1),
                unit: 'km',
                label: 'Distance',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                icon: Icons.timer_outlined,
                value: '$durationMinutes',
                unit: 'min',
                label: 'Duration',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                icon: Icons.local_gas_station_rounded,
                value: fuelLiters.toStringAsFixed(1),
                unit: 'L',
                label: 'Fuel used',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                teal.withValues(alpha: 0.1),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: teal.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_rounded, size: 18, color: teal),
                  const SizedBox(width: 8),
                  Text(
                    'AI insights',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AiStreamingText(text: summary, stream: streamSummary),
              if (highlights.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final h in highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 16, color: teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            h,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Tips for next time',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          AiRecommendationCards(recommendations: recommendations),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onShare();
                },
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onSave();
                },
                icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                label: const Text('Save'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
