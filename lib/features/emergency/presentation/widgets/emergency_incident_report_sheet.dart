import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_type.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';

/// Guided accident / incident reporting flow.
class EmergencyIncidentReportSheet extends ConsumerStatefulWidget {
  const EmergencyIncidentReportSheet({super.key});

  @override
  ConsumerState<EmergencyIncidentReportSheet> createState() =>
      _EmergencyIncidentReportSheetState();
}

class _EmergencyIncidentReportSheetState
    extends ConsumerState<EmergencyIncidentReportSheet> {
  EmergencyType _type = EmergencyType.accident;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Report Incident', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<EmergencyType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Incident type'),
            items: EmergencyType.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.displayName),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _type = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Driver notes',
              hintText: 'Describe what happened',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.photo_camera),
            title: Text('Photo attachments'),
            subtitle: Text('Camera integration placeholder'),
          ),
          const ListTile(
            leading: Icon(Icons.videocam),
            title: Text('Video attachment'),
            subtitle: Text('Placeholder — future release'),
          ),
          const ListTile(
            leading: Icon(Icons.mic),
            title: Text('Voice note'),
            subtitle: Text('Placeholder — future release'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await ref.read(emergencyControllerProvider.notifier).reportIncident(
                    type: _type,
                    driverNotes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}
