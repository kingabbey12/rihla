/// On-device medical profile — never transmitted unless user explicitly shares.
class MedicalProfile {
  const MedicalProfile({
    this.bloodType,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.emergencyMedications = const [],
    this.organDonorPreference,
    this.emergencyNotes,
    this.emergencyContactId,
  });

  final String? bloodType;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> emergencyMedications;
  final bool? organDonorPreference;
  final String? emergencyNotes;
  final String? emergencyContactId;

  static const empty = MedicalProfile();

  bool get isEmpty =>
      bloodType == null &&
      allergies.isEmpty &&
      medicalConditions.isEmpty &&
      emergencyMedications.isEmpty &&
      organDonorPreference == null &&
      emergencyNotes == null &&
      emergencyContactId == null;

  Map<String, dynamic> toJson() => {
        if (bloodType != null) 'bloodType': bloodType,
        'allergies': allergies,
        'medicalConditions': medicalConditions,
        'emergencyMedications': emergencyMedications,
        if (organDonorPreference != null)
          'organDonorPreference': organDonorPreference,
        if (emergencyNotes != null) 'emergencyNotes': emergencyNotes,
        if (emergencyContactId != null)
          'emergencyContactId': emergencyContactId,
      };

  factory MedicalProfile.fromJson(Map<String, dynamic> json) => MedicalProfile(
        bloodType: json['bloodType'] as String?,
        allergies: (json['allergies'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        medicalConditions: (json['medicalConditions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        emergencyMedications: (json['emergencyMedications'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        organDonorPreference: json['organDonorPreference'] as bool?,
        emergencyNotes: json['emergencyNotes'] as String?,
        emergencyContactId: json['emergencyContactId'] as String?,
      );

  MedicalProfile copyWith({
    String? bloodType,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? emergencyMedications,
    bool? organDonorPreference,
    String? emergencyNotes,
    String? emergencyContactId,
  }) =>
      MedicalProfile(
        bloodType: bloodType ?? this.bloodType,
        allergies: allergies ?? this.allergies,
        medicalConditions: medicalConditions ?? this.medicalConditions,
        emergencyMedications: emergencyMedications ?? this.emergencyMedications,
        organDonorPreference:
            organDonorPreference ?? this.organDonorPreference,
        emergencyNotes: emergencyNotes ?? this.emergencyNotes,
        emergencyContactId: emergencyContactId ?? this.emergencyContactId,
      );
}
