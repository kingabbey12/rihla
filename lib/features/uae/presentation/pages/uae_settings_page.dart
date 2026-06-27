import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/uae/domain/entities/uae_region.dart';
import 'package:rihla/features/uae/domain/models/uae_state.dart';
import 'package:rihla/features/uae/presentation/providers/uae_providers.dart';

/// UAE intelligence settings page.
class UaeSettingsPage extends ConsumerWidget {
  const UaeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(uaePreferencesProvider);
    final state = ref.watch(uaeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('UAE Intelligence')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state is UaeReady) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_city),
                title: Text('Current emirate: ${state.snapshot.region.displayName}'),
                subtitle: state.snapshot.roadType != null
                    ? Text('Road type: ${state.snapshot.roadType}')
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            if (state.snapshot.salikSummary.estimatedTollCount > 0)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.toll),
                  title: Text(
                    'Salik: ${state.snapshot.salikSummary.estimatedTollCount} gates',
                  ),
                  subtitle: Text(
                    'Estimated AED ${state.snapshot.salikSummary.estimatedTotalAed.toStringAsFixed(0)} (informational)',
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text('Preferred Emirate', style: Theme.of(context).textTheme.titleMedium),
          ...UaeRegion.values.map(
            (region) => RadioListTile<UaeRegion>(
              title: Text(region.displayName),
              value: region,
              groupValue: prefs.preferredRegion,
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(uaeControllerProvider.notifier)
                      .updatePreferences(prefs.copyWith(preferredRegion: value));
                }
              },
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Metric units'),
            value: prefs.useMetricUnits,
            onChanged: (v) => ref
                .read(uaeControllerProvider.notifier)
                .updatePreferences(prefs.copyWith(useMetricUnits: v)),
          ),
          SwitchListTile(
            title: const Text('Salik alerts'),
            subtitle: const Text('Upcoming toll gate notifications'),
            value: prefs.salikAlertsEnabled,
            onChanged: (v) => ref
                .read(uaeControllerProvider.notifier)
                .updatePreferences(prefs.copyWith(salikAlertsEnabled: v)),
          ),
          SwitchListTile(
            title: const Text('Camera alerts'),
            subtitle: const Text('Speed and red-light camera warnings'),
            value: prefs.cameraAlertsEnabled,
            onChanged: (v) => ref
                .read(uaeControllerProvider.notifier)
                .updatePreferences(prefs.copyWith(cameraAlertsEnabled: v)),
          ),
          SwitchListTile(
            title: const Text('Weather alerts'),
            value: prefs.weatherAlertsEnabled,
            onChanged: (v) => ref
                .read(uaeControllerProvider.notifier)
                .updatePreferences(prefs.copyWith(weatherAlertsEnabled: v)),
          ),
          SwitchListTile(
            title: const Text('Holiday traffic alerts'),
            value: prefs.holidayTrafficAlertsEnabled,
            onChanged: (v) => ref
                .read(uaeControllerProvider.notifier)
                .updatePreferences(prefs.copyWith(holidayTrafficAlertsEnabled: v)),
          ),
          const Divider(),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(prefs.languageCode == 'ar' ? 'Arabic' : 'English'),
            trailing: DropdownButton<String>(
              value: prefs.languageCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('Arabic')),
              ],
              onChanged: (code) {
                if (code != null) {
                  ref
                      .read(uaeControllerProvider.notifier)
                      .updatePreferences(prefs.copyWith(languageCode: code));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
