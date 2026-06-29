import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/platform/phone_launcher.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/uae/domain/entities/uae_intelligence_snapshot.dart';

/// UAE emergency numbers and nearest hospitals/police from live data.
class EmergencyUaeServicesSection extends ConsumerWidget {
  const EmergencyUaeServicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(uaeEmergencyContactsProvider);
    final hospitals = ref.watch(emergencyNearbyHospitalsProvider);
    final police = ref.watch(emergencyNearbyPoliceProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UAE emergency numbers',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        contacts.when(
          data: (list) => _ContactGrid(contacts: list),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('Could not load emergency numbers'),
        ),
        const SizedBox(height: 20),
        Text(
          'Nearby hospitals',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        hospitals.when(
          data: (places) => _NearbyList(places: places, emptyLabel: 'No hospitals found nearby'),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('Could not load nearby hospitals'),
        ),
        const SizedBox(height: 16),
        Text(
          'Nearby police',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        police.when(
          data: (places) => _NearbyList(places: places, emptyLabel: 'No police stations found nearby'),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('Could not load nearby police'),
        ),
      ],
    );
  }
}

class _ContactGrid extends StatelessWidget {
  const _ContactGrid({required this.contacts});

  final List<UaeEmergencyContact> contacts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Deduplicate by category — show one entry per service type.
    final seen = <String>{};
    final unique = <UaeEmergencyContact>[];
    for (final c in contacts) {
      if (seen.add(c.category)) unique.add(c);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: unique.map((c) {
        return ActionChip(
          avatar: Icon(_iconFor(c.category), size: 18),
          label: Text('${c.name} · ${c.number}'),
          onPressed: () => PhoneLauncher.dial(c.number),
          backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        );
      }).toList(),
    );
  }

  IconData _iconFor(String category) => switch (category) {
        'police' => Icons.local_police,
        'ambulance' => Icons.medical_services,
        'fire' => Icons.local_fire_department,
        'roadside' => Icons.car_repair,
        'poison' => Icons.healing,
        _ => Icons.phone,
      };
}

class _NearbyList extends StatelessWidget {
  const _NearbyList({required this.places, required this.emptyLabel});

  final List<ExplorePlace> places;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (places.isEmpty) {
      return Text(
        emptyLabel,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      children: places.map((p) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.place_outlined),
          title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              if (p.distanceKm != null)
                '${p.distanceKm!.toStringAsFixed(1)} km',
              if (p.etaMinutes != null) '~${p.etaMinutes} min',
              if (p.phone != null) p.phone!,
            ].join(' · '),
          ),
          trailing: p.phone != null
              ? IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () => PhoneLauncher.dial(p.phone!),
                )
              : null,
        );
      }).toList(),
    );
  }
}
