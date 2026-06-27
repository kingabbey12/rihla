import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_contact.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';

/// On-device medical and vehicle profile editor.
class EmergencyProfileSheet extends ConsumerStatefulWidget {
  const EmergencyProfileSheet({super.key});

  @override
  ConsumerState<EmergencyProfileSheet> createState() =>
      _EmergencyProfileSheetState();
}

class _EmergencyProfileSheetState extends ConsumerState<EmergencyProfileSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  MedicalProfile _medical = MedicalProfile.empty;
  EmergencyVehicleProfile _vehicle = EmergencyVehicleProfile.empty;
  bool _loaded = false;

  final _bloodType = TextEditingController();
  final _allergies = TextEditingController();
  final _conditions = TextEditingController();
  final _medications = TextEditingController();
  final _notes = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _plate = TextEditingController();
  final _insurance = TextEditingController();
  bool _organDonor = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final controller = ref.read(emergencyControllerProvider.notifier);
    _medical = await controller.getMedicalProfile();
    _vehicle = await controller.getVehicleProfile();
    _bloodType.text = _medical.bloodType ?? '';
    _allergies.text = _medical.allergies.join(', ');
    _conditions.text = _medical.medicalConditions.join(', ');
    _medications.text = _medical.emergencyMedications.join(', ');
    _notes.text = _medical.emergencyNotes ?? '';
    _organDonor = _medical.organDonorPreference ?? false;
    _make.text = _vehicle.make ?? '';
    _model.text = _vehicle.model ?? '';
    _plate.text = _vehicle.licensePlate ?? '';
    _insurance.text = _vehicle.insuranceProvider ?? '';
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _bloodType.dispose();
    _allergies.dispose();
    _conditions.dispose();
    _medications.dispose();
    _notes.dispose();
    _make.dispose();
    _model.dispose();
    _plate.dispose();
    _insurance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Medical'),
            Tab(text: 'Vehicle'),
          ],
        ),
        SizedBox(
          height: 360,
          child: TabBarView(
            controller: _tabs,
            children: [
              _MedicalTab(
                bloodType: _bloodType,
                allergies: _allergies,
                conditions: _conditions,
                medications: _medications,
                notes: _notes,
                organDonor: _organDonor,
                onOrganDonorChanged: (v) => setState(() => _organDonor = v),
              ),
              _VehicleTab(
                make: _make,
                model: _model,
                plate: _plate,
                insurance: _insurance,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _save,
            child: const Text('Save profiles (on-device only)'),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final controller = ref.read(emergencyControllerProvider.notifier);
    await controller.saveMedicalProfile(
      MedicalProfile(
        bloodType: _bloodType.text.trim().isEmpty ? null : _bloodType.text.trim(),
        allergies: _splitList(_allergies.text),
        medicalConditions: _splitList(_conditions.text),
        emergencyMedications: _splitList(_medications.text),
        organDonorPreference: _organDonor,
        emergencyNotes:
            _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
    await controller.saveVehicleProfile(
      EmergencyVehicleProfile(
        make: _make.text.trim().isEmpty ? null : _make.text.trim(),
        model: _model.text.trim().isEmpty ? null : _model.text.trim(),
        licensePlate: _plate.text.trim().isEmpty ? null : _plate.text.trim(),
        insuranceProvider:
            _insurance.text.trim().isEmpty ? null : _insurance.text.trim(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  List<String> _splitList(String text) => text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

class _MedicalTab extends StatelessWidget {
  const _MedicalTab({
    required this.bloodType,
    required this.allergies,
    required this.conditions,
    required this.medications,
    required this.notes,
    required this.organDonor,
    required this.onOrganDonorChanged,
  });

  final TextEditingController bloodType;
  final TextEditingController allergies;
  final TextEditingController conditions;
  final TextEditingController medications;
  final TextEditingController notes;
  final bool organDonor;
  final ValueChanged<bool> onOrganDonorChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: bloodType,
          decoration: const InputDecoration(labelText: 'Blood type'),
        ),
        TextField(
          controller: allergies,
          decoration: const InputDecoration(
            labelText: 'Allergies (comma-separated)',
          ),
        ),
        TextField(
          controller: conditions,
          decoration: const InputDecoration(
            labelText: 'Medical conditions',
          ),
        ),
        TextField(
          controller: medications,
          decoration: const InputDecoration(
            labelText: 'Emergency medications',
          ),
        ),
        TextField(
          controller: notes,
          decoration: const InputDecoration(labelText: 'Emergency notes'),
          maxLines: 2,
        ),
        SwitchListTile(
          title: const Text('Organ donor preference'),
          value: organDonor,
          onChanged: onOrganDonorChanged,
        ),
      ],
    );
  }
}

class _VehicleTab extends StatelessWidget {
  const _VehicleTab({
    required this.make,
    required this.model,
    required this.plate,
    required this.insurance,
  });

  final TextEditingController make;
  final TextEditingController model;
  final TextEditingController plate;
  final TextEditingController insurance;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(controller: make, decoration: const InputDecoration(labelText: 'Make')),
        TextField(controller: model, decoration: const InputDecoration(labelText: 'Model')),
        TextField(
          controller: plate,
          decoration: const InputDecoration(labelText: 'License plate'),
        ),
        TextField(
          controller: insurance,
          decoration: const InputDecoration(labelText: 'Insurance provider'),
        ),
      ],
    );
  }
}

/// Quick-dial emergency contacts list.
class EmergencyContactsSheet extends ConsumerWidget {
  const EmergencyContactsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(emergencyContactsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Emergency Contacts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          contactsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Could not load contacts.'),
            data: (contacts) {
              if (contacts.isEmpty) {
                return const Text('No contacts saved yet.');
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: contacts
                    .map(
                      (c) => ListTile(
                        leading: Icon(
                          c.isFavorite ? Icons.star : Icons.person,
                          color: c.isFavorite ? Colors.amber : null,
                        ),
                        title: Text(c.name),
                        subtitle: Text('${c.category.displayName} · ${c.phone}'),
                        trailing: const Icon(Icons.phone),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dial ${c.phone}')),
                          );
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
