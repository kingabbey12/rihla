import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_state.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_type.dart';
import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/emergency/presentation/widgets/emergency_sos_countdown_sheet.dart';

/// Map overlay with emergency actions and SOS flow.
class EmergencyMapOverlay extends ConsumerWidget {
  const EmergencyMapOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(emergencyControllerProvider);
    final active = ref.watch(emergencyActiveProvider);
    final bottom = 100 + MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        // Action bar only appears in emergency mode (Emergency tab / launcher),
        // keeping the idle Home Dashboard clean.
        if (active)
          Positioned(
            left: 12,
            bottom: bottom,
            child: _EmergencyActionBar(
              onSos: () => ref
                  .read(emergencyControllerProvider.notifier)
                  .startSosCountdown(),
              onRoadside: () => _showRoadsideSheet(context, ref),
              onHospital: () => ref
                  .read(emergencyControllerProvider.notifier)
                  .openNearestHospital(),
              onPolice: () => ref
                  .read(emergencyControllerProvider.notifier)
                  .openNearestPolice(),
            ),
          ),
        if (state is EmergencySosCountdown)
          EmergencySosCountdownSheet(
            secondsRemaining: state.secondsRemaining,
            onCancel: () =>
                ref.read(emergencyControllerProvider.notifier).cancelSos(),
          ),
        if (state is EmergencySosConfirming)
          const Center(child: CircularProgressIndicator()),
        if (state is EmergencySosSent)
          _StatusBanner(
            message: state.queued
                ? 'SOS queued — will send when online'
                : 'SOS sent successfully',
            color: Colors.red.shade700,
            onDismiss: () =>
                ref.read(emergencyControllerProvider.notifier).refresh(),
          ),
        if (state is EmergencyRoadsideActive)
          _StatusBanner(
            message: '${state.request.type.displayName} request submitted',
            color: Colors.orange.shade800,
            onDismiss: () =>
                ref.read(emergencyControllerProvider.notifier).refresh(),
          ),
      ],
    );
  }

  void _showRoadsideSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _RoadsideSheet(
        onSelect: (type) async {
          Navigator.of(ctx).pop();
          await ref
              .read(emergencyControllerProvider.notifier)
              .requestRoadside(type);
        },
      ),
    );
  }
}

class _EmergencyActionBar extends StatelessWidget {
  const _EmergencyActionBar({
    required this.onSos,
    required this.onRoadside,
    required this.onHospital,
    required this.onPolice,
  });

  final VoidCallback onSos;
  final VoidCallback onRoadside;
  final VoidCallback onHospital;
  final VoidCallback onPolice;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FloatingActionButton.extended(
          heroTag: 'sos',
          backgroundColor: Colors.red.shade700,
          onPressed: onSos,
          icon: const Icon(Icons.sos),
          label: const Text('SOS'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ShortcutButton(
              icon: Icons.car_repair,
              label: 'Roadside',
              onPressed: onRoadside,
            ),
            _ShortcutButton(
              icon: Icons.local_hospital,
              label: 'Hospital',
              onPressed: onHospital,
            ),
            _ShortcutButton(
              icon: Icons.local_police,
              label: 'Police',
              onPressed: onPolice,
            ),
          ],
        ),
      ],
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.color,
    required this.onDismiss,
  });

  final String message;
  final Color color;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 64,
      left: 16,
      right: 16,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          title: Text(message, style: const TextStyle(color: Colors.white)),
          trailing: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onDismiss,
          ),
        ),
      ),
    );
  }
}

class _RoadsideSheet extends StatelessWidget {
  const _RoadsideSheet({required this.onSelect});

  final ValueChanged<RoadsideRequestType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Roadside Assistance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...RoadsideRequestType.values.map(
            (type) => ListTile(
              leading: const Icon(Icons.build_circle_outlined),
              title: Text(type.displayName),
              onTap: () => onSelect(type),
            ),
          ),
        ],
      ),
    );
  }
}
