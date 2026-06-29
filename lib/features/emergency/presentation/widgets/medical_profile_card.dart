import 'package:flutter/material.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';

/// Premium read-only summary of the on-device medical profile.
class MedicalProfileCard extends StatelessWidget {
  const MedicalProfileCard({
    required this.profile,
    required this.onEdit,
    super.key,
  });

  final MedicalProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFFE53935);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.medical_services_rounded,
                    color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medical Profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'On-device only · shared during SOS',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit medical profile',
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (profile.isEmpty)
            _EmptyHint(
              text: 'Add your blood type, allergies, and conditions so '
                  'responders can help faster.',
              onAdd: onEdit,
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (profile.bloodType != null)
                  _Chip(
                    icon: Icons.bloodtype_rounded,
                    label: 'Blood',
                    value: profile.bloodType!,
                    accent: accent,
                  ),
                if (profile.allergies.isNotEmpty)
                  _Chip(
                    icon: Icons.warning_amber_rounded,
                    label: 'Allergies',
                    value: profile.allergies.join(', '),
                    accent: accent,
                  ),
                if (profile.medicalConditions.isNotEmpty)
                  _Chip(
                    icon: Icons.favorite_rounded,
                    label: 'Conditions',
                    value: profile.medicalConditions.join(', '),
                    accent: accent,
                  ),
                if (profile.emergencyMedications.isNotEmpty)
                  _Chip(
                    icon: Icons.medication_rounded,
                    label: 'Medications',
                    value: profile.emergencyMedications.join(', '),
                    accent: accent,
                  ),
                if (profile.emergencyNotes != null)
                  _Chip(
                    icon: Icons.notes_rounded,
                    label: 'Notes',
                    value: profile.emergencyNotes!,
                    accent: accent,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text, required this.onAdd});

  final String text;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add medical details'),
        ),
      ],
    );
  }
}
