import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/platform/phone_launcher.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_state.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/emergency/presentation/widgets/emergency_profile_sheet.dart';
import 'package:rihla/features/emergency/presentation/widgets/emergency_service_card.dart';
import 'package:rihla/features/emergency/presentation/widgets/emergency_sos_countdown_sheet.dart';
import 'package:rihla/features/emergency/presentation/widgets/emergency_timeline_view.dart';
import 'package:rihla/features/emergency/presentation/widgets/medical_profile_card.dart';
import 'package:rihla/features/emergency/presentation/widgets/roadside_request_sheet.dart';
import 'package:rihla/features/emergency/presentation/widgets/sos_button.dart';
import 'package:rihla/features/emergency/presentation/widgets/vehicle_profile_card.dart';
import 'package:rihla/features/emergency/presentation/widgets/emergency_uae_services_section.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

/// Full-screen premium Emergency hub.
class EmergencyDashboardPage extends ConsumerStatefulWidget {
  const EmergencyDashboardPage({super.key});

  @override
  ConsumerState<EmergencyDashboardPage> createState() =>
      _EmergencyDashboardPageState();
}

class _EmergencyDashboardPageState
    extends ConsumerState<EmergencyDashboardPage> {
  MedicalProfile _medical = MedicalProfile.empty;
  EmergencyVehicleProfile _vehicle = EmergencyVehicleProfile.empty;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    // Ensure GPS is active so emergency workflows use real coordinates.
    Future.microtask(() {
      ref.read(locationControllerProvider.notifier).startForegroundStream();
    });
  }

  Future<void> _loadProfiles() async {
    final controller = ref.read(emergencyControllerProvider.notifier);
    MedicalProfile medical = MedicalProfile.empty;
    EmergencyVehicleProfile vehicle = EmergencyVehicleProfile.empty;
    try {
      medical = await controller.getMedicalProfile();
      vehicle = await controller.getVehicleProfile();
    } catch (_) {
      // Secure storage may be unavailable (e.g. first run / test harness).
      // Fall back to empty profiles so the hub still renders.
    }
    if (!mounted) return;
    setState(() {
      _medical = medical;
      _vehicle = vehicle;
    });
  }

  Future<void> _editProfiles() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const SafeArea(child: EmergencyProfileSheet()),
    );
    await _loadProfiles();
  }

  void _openRoadside() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const RoadsideRequestSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(emergencyControllerProvider);
    final controller = ref.read(emergencyControllerProvider.notifier);
    final locationState = ref.watch(locationControllerProvider);
    final timeline = ref.watch(emergencyRepositoryProvider).getActiveTimeline();

    final (lat, lng) = switch (locationState) {
      LocationActive(:final position) => (
          position.latitude,
          position.longitude,
        ),
      _ => (0.0, 0.0),
    };

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        title: const Text('Emergency'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Center(
                child: SosButton(onPressed: controller.startSosCountdown),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Tap SOS for emergency assistance',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _LocationCard(
                latitude: lat,
                longitude: lng,
                hasGps: locationState is LocationActive,
                onShare: controller.shareLocation,
              ),
              const SizedBox(height: 24),
              const EmergencyUaeServicesSection(),
              const SizedBox(height: 24),
              Text(
                'Get help',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  EmergencyServiceCard(
                    icon: Icons.car_repair_rounded,
                    title: 'Roadside Assistance',
                    subtitle: 'Tow, battery, fuel & more',
                    color: const Color(0xFFF57C00),
                    onTap: _openRoadside,
                  ),
                  EmergencyServiceCard(
                    icon: Icons.local_hospital_rounded,
                    title: 'Medical Assistance',
                    subtitle: 'Nearest hospital',
                    color: const Color(0xFF2E7D32),
                    onTap: controller.openNearestHospital,
                  ),
                  EmergencyServiceCard(
                    icon: Icons.local_police_rounded,
                    title: 'Police',
                    subtitle: 'Nearest station',
                    color: const Color(0xFF1565C0),
                    onTap: controller.openNearestPolice,
                  ),
                  EmergencyServiceCard(
                    icon: Icons.local_fire_department_rounded,
                    title: 'Fire',
                    subtitle: 'Call 997',
                    color: const Color(0xFFD84315),
                    onTap: () => PhoneLauncher.dial('997'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ReportIncidentBanner(
                onTap: () => context.push(RoutePaths.reportIncident),
              ),
              const SizedBox(height: 24),
              Text(
                'Your profiles',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              MedicalProfileCard(profile: _medical, onEdit: _editProfiles),
              const SizedBox(height: 12),
              VehicleProfileCard(profile: _vehicle, onEdit: _editProfiles),
              if (timeline != null && timeline.events.isNotEmpty) ...[
                const SizedBox(height: 24),
                EmergencyTimelineView(timeline: timeline),
              ],
            ],
          ),
          if (state is EmergencySosCountdown)
            EmergencySosCountdownSheet(
              secondsRemaining: state.secondsRemaining,
              onCancel: controller.cancelSos,
            ),
          if (state is EmergencySosConfirming)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (state is EmergencySosSent)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24 + MediaQuery.paddingOf(context).bottom,
              child: _SentBanner(
                queued: state.queued,
                onDismiss: controller.refresh,
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.latitude,
    required this.longitude,
    required this.hasGps,
    required this.onShare,
  });

  final double latitude;
  final double longitude;
  final bool hasGps;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: RihlaReferenceTokens.mapTeal.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.my_location_rounded,
                color: RihlaReferenceTokens.mapTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current location',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasGps
                      ? '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}'
                      : 'Waiting for GPS…',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () => onShare(),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

class _ReportIncidentBanner extends StatelessWidget {
  const _ReportIncidentBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.report_rounded,
                    color: Color(0xFFE53935)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report an incident',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Accident, hazard, flood, road closure',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SentBanner extends StatelessWidget {
  const _SentBanner({required this.queued, required this.onDismiss});

  final bool queued;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFC62828),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                queued
                    ? 'SOS queued — will send when back online'
                    : 'SOS sent. Help is on the way.',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
