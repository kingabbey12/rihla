import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/constants/app_constants.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';

/// Development-only page for inspecting live location data.
///
/// Not linked from the main UI. Navigate directly to `/debug/location`.
class LocationDebugPage extends ConsumerStatefulWidget {
  const LocationDebugPage({super.key});

  @override
  ConsumerState<LocationDebugPage> createState() => _LocationDebugPageState();
}

class _LocationDebugPageState extends ConsumerState<LocationDebugPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(locationControllerProvider.notifier).refreshStatus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationControllerProvider);
    final accuracy = ref.watch(locationAccuracyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Location Debug')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          _SectionTitle('Controls'),
          _AccuracySelector(
            value: accuracy,
            onChanged: (level) =>
                ref.read(locationAccuracyProvider.notifier).setAccuracy(level),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                label: 'Refresh Status',
                onPressed: () =>
                    ref.read(locationControllerProvider.notifier).refreshStatus(),
              ),
              _ActionChip(
                label: 'Request Permission',
                onPressed: () => ref
                    .read(locationControllerProvider.notifier)
                    .requestPermission(),
              ),
              _ActionChip(
                label: 'Get Position',
                onPressed: () => ref
                    .read(locationControllerProvider.notifier)
                    .fetchCurrentPosition(),
              ),
              _ActionChip(
                label: 'Start Stream',
                onPressed: () => ref
                    .read(locationControllerProvider.notifier)
                    .startForegroundStream(),
              ),
              _ActionChip(
                label: 'Stop Stream',
                onPressed: () =>
                    ref.read(locationControllerProvider.notifier).stopStream(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle('Status'),
          _InfoCard(children: _statusRows(locationState)),
          const SizedBox(height: 24),
          _SectionTitle('Position'),
          _InfoCard(children: _positionRows(locationState)),
        ],
      ),
    );
  }

  List<Widget> _statusRows(LocationState state) {
    final permission = switch (state) {
      LocationIdle(:final permissionStatus) => permissionStatus,
      LocationLoading(:final permissionStatus) => permissionStatus,
      LocationActive(:final permissionStatus) => permissionStatus,
      LocationError(:final permissionStatus) => permissionStatus,
    };
    final gps = switch (state) {
      LocationIdle(:final gpsStatus) => gpsStatus,
      LocationLoading(:final gpsStatus) => gpsStatus,
      LocationActive(:final gpsStatus) => gpsStatus,
      LocationError(:final gpsStatus) => gpsStatus,
    };

    return [
      _InfoRow('State', state.runtimeType.toString()),
      _InfoRow('Permission', _formatPermission(permission)),
      _InfoRow('GPS', _formatGps(gps)),
      if (state is LocationError)
        _InfoRow('Error', state.failure.message),
      if (state is LocationActive && state.isStreaming)
        const _InfoRow('Mode', 'Foreground stream'),
    ];
  }

  List<Widget> _positionRows(LocationState state) {
    final position = switch (state) {
      LocationActive(:final position) => position,
      LocationError(:final lastKnownPosition) => lastKnownPosition,
      _ => null,
    };

    if (position == null) {
      return [const _InfoRow('—', 'No position available')];
    }

    return [
      _InfoRow('Latitude', position.latitude.toStringAsFixed(6)),
      _InfoRow('Longitude', position.longitude.toStringAsFixed(6)),
      _InfoRow('Accuracy', '${position.accuracy.toStringAsFixed(1)} m'),
      _InfoRow('Speed', _formatOptional(position.speed, 'm/s')),
      _InfoRow('Heading', _formatOptional(position.heading, '°')),
      _InfoRow('Altitude', _formatOptional(position.altitude, 'm')),
      _InfoRow('Timestamp', position.timestamp.toIso8601String()),
    ];
  }

  String _formatPermission(LocationPermissionStatus status) =>
      switch (status) {
        LocationPermissionStatus.granted => 'Granted',
        LocationPermissionStatus.denied => 'Denied',
        LocationPermissionStatus.permanentlyDenied => 'Permanently Denied',
        LocationPermissionStatus.unknown => 'Unknown',
      };

  String _formatGps(GpsServiceStatus status) => switch (status) {
        GpsServiceStatus.enabled => 'Enabled',
        GpsServiceStatus.disabled => 'Disabled',
        GpsServiceStatus.unknown => 'Unknown',
      };

  String _formatOptional(double? value, String unit) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(2)} $unit';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: context.textTheme.titleMedium),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: context.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onPressed);
  }
}

class _AccuracySelector extends StatelessWidget {
  const _AccuracySelector({required this.value, required this.onChanged});

  final LocationAccuracyLevel value;
  final ValueChanged<LocationAccuracyLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<LocationAccuracyLevel>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Accuracy'),
      items: LocationAccuracyLevel.values
          .map(
            (level) => DropdownMenuItem(
              value: level,
              child: Text(level.name),
            ),
          )
          .toList(),
      onChanged: (level) {
        if (level != null) onChanged(level);
      },
    );
  }
}
