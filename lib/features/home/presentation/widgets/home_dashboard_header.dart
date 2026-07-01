import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/home/presentation/providers/home_dashboard_providers.dart';
import 'package:rihla/features/home/presentation/widgets/home_dashboard_entrance.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/weather/presentation/providers/weather_providers.dart';
import 'package:rihla/shared/design/rihla_glass.dart';
import 'package:rihla/shared/design/rihla_radii.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

class HomeDashboardHeader extends ConsumerWidget {
  const HomeDashboardHeader({super.key});

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final l10n = context.l10n;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 17) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
  }

  IconData _weatherIcon(String? summary) {
    final s = (summary ?? '').toLowerCase();
    if (s.contains('rain') || s.contains('drizzle') || s.contains('storm')) {
      return Icons.grain_rounded;
    }
    if (s.contains('cloud')) return Icons.cloud_rounded;
    if (s.contains('clear') || s.contains('sun')) return Icons.wb_sunny_rounded;
    return Icons.wb_cloudy_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final displayName = ref.watch(homeDisplayNameProvider);
    final name = displayName.isNotEmpty ? displayName : l10n.homeGuestName;
    final locationAsync = ref.watch(homeLocationAddressProvider);
    final locationState = ref.watch(locationControllerProvider);
    final hasFix = locationState is LocationActive;
    final weather = ref.watch(weatherSnapshotProvider);
    final timeLabel = DateFormat.jm().format(DateTime.now());
    final temp = weather?.current.temperatureCelsius;

    return HomeDashboardEntrance(
      fromTop: true,
      child: RihlaGlassSurface(
        borderRadius: RihlaRadii.cardAll,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_greeting(context)}, $name',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasFix ? Icons.my_location_rounded : Icons.location_searching_rounded,
                  size: 18,
                  color: RihlaReferenceTokens.mapTeal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: locationAsync.when(
                    loading: () => const HomeSkeletonBox(height: 14, width: 180),
                    error: (_, _) => Text(
                      hasFix ? l10n.homeCurrentLocationLabel : l10n.homeLocatingLabel,
                      style: theme.textTheme.bodyMedium,
                    ),
                    data: (label) => Text(
                      label.isNotEmpty
                          ? label
                          : (hasFix
                              ? l10n.homeCurrentLocationLabel
                              : l10n.homeLocatingLabel),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _weatherIcon(weather?.current.summary),
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    weather != null
                        ? '${weather.current.summary} · ${temp?.round() ?? '—'}°C'
                        : l10n.loadingMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  timeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
