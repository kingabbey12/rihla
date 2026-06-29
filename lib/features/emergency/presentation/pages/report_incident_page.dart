import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_type.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/shared/ui/rihla_reference_tokens.dart';

typedef _IncidentChoice = ({EmergencyType type, String label, IconData icon});

/// Premium step-based incident reporting wizard.
class ReportIncidentPage extends ConsumerStatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  ConsumerState<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends ConsumerState<ReportIncidentPage> {
  static const _steps = 3;
  int _step = 0;
  _IncidentChoice _choice = _choices.first;
  bool _photoAttached = false;
  bool _voiceAttached = false;
  final _notes = TextEditingController();
  bool _submitting = false;

  static const List<_IncidentChoice> _choices = [
    (type: EmergencyType.accident, label: 'Accident', icon: Icons.car_crash_rounded),
    (
      type: EmergencyType.dangerousRoad,
      label: 'Hazard',
      icon: Icons.warning_amber_rounded
    ),
    (type: EmergencyType.flood, label: 'Flood', icon: Icons.water_rounded),
    (
      type: EmergencyType.roadObstruction,
      label: 'Road Closure',
      icon: Icons.block_rounded
    ),
    (
      type: EmergencyType.vehicleBreakdown,
      label: 'Broken Vehicle',
      icon: Icons.car_repair_rounded
    ),
  ];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step < _steps - 1) {
      HapticFeedback.selectionClick();
      setState(() => _step++);
      return;
    }
    setState(() => _submitting = true);
    await ref.read(emergencyControllerProvider.notifier).reportIncident(
          type: _choice.type,
          photoPaths: _photoAttached ? const ['pending_photo_attachment'] : const [],
          driverNotes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (mounted) context.pop();
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProgressIndicator(step: _step, total: _steps),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _buildStep(theme),
                ),
              ),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _submitting ? null : _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: RihlaReferenceTokens.emergencyRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _step < _steps - 1 ? 'Continue' : 'Submit Report',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme) {
    return switch (_step) {
      0 => _stepType(theme),
      1 => _stepDetails(theme),
      _ => _stepReview(theme),
    };
  }

  Widget _stepType(ThemeData theme) {
    return ListView(
      key: const ValueKey('type'),
      children: [
        Text(
          'What happened?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the type of incident to report.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        for (final choice in _choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ChoiceCard(
              choice: choice,
              selected: _choice == choice,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _choice = choice);
              },
            ),
          ),
      ],
    );
  }

  Widget _stepDetails(ThemeData theme) {
    return ListView(
      key: const ValueKey('details'),
      children: [
        Text(
          'Add details',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Attachments help responders understand the situation.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MediaPlaceholder(
                icon: Icons.photo_camera_rounded,
                label: 'Add photo',
                attached: _photoAttached,
                onTap: () => setState(() => _photoAttached = !_photoAttached),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MediaPlaceholder(
                icon: Icons.mic_rounded,
                label: 'Voice note',
                attached: _voiceAttached,
                onTap: () => setState(() => _voiceAttached = !_voiceAttached),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _notes,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'Describe what you saw…',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepReview(ThemeData theme) {
    final camera = ref.watch(mapCameraProvider);
    return ListView(
      key: const ValueKey('review'),
      children: [
        Text(
          'Review & submit',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        _ReviewRow(
          icon: _choice.icon,
          label: 'Incident',
          value: _choice.label,
        ),
        _ReviewRow(
          icon: Icons.attach_file_rounded,
          label: 'Attachments',
          value: [
            if (_photoAttached) 'Photo',
            if (_voiceAttached) 'Voice note',
          ].join(', ').ifEmpty('None'),
        ),
        const SizedBox(height: 16),
        _LocationPreview(
          latitude: camera.latitude,
          longitude: camera.longitude,
        ),
      ],
    );
  }
}

extension _StringX on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${step + 1} of $total',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= step
                        ? RihlaReferenceTokens.emergencyRed
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i < total - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _IncidentChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = RihlaReferenceTokens.emergencyRed;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(choice.icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                choice.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({
    required this.icon,
    required this.label,
    required this.attached,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool attached;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 110,
        decoration: BoxDecoration(
          color: attached
              ? accent.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: attached ? accent : theme.colorScheme.outlineVariant,
            width: attached ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              attached ? Icons.check_circle_rounded : icon,
              color: attached ? accent : theme.colorScheme.onSurfaceVariant,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              attached ? 'Added' : label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: attached ? accent : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: RihlaReferenceTokens.mapTeal.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.place_rounded,
                color: RihlaReferenceTokens.mapTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incident location',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
