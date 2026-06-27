/// Emergency-related profile data eligible for cloud sync.
class UserEmergencyProfile {
  const UserEmergencyProfile({
    this.contacts = const [],
    this.medicalSummary = const {},
    this.updatedAt,
  });

  final List<Map<String, dynamic>> contacts;
  final Map<String, String> medicalSummary;
  final DateTime? updatedAt;

  bool get isEmpty => contacts.isEmpty && medicalSummary.isEmpty;

  UserEmergencyProfile copyWith({
    List<Map<String, dynamic>>? contacts,
    Map<String, String>? medicalSummary,
    DateTime? updatedAt,
  }) {
    return UserEmergencyProfile(
      contacts: contacts ?? this.contacts,
      medicalSummary: medicalSummary ?? this.medicalSummary,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'contacts': contacts,
        'medicalSummary': medicalSummary,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory UserEmergencyProfile.fromJson(Map<String, dynamic> json) {
    return UserEmergencyProfile(
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      medicalSummary: Map<String, String>.from(
        json['medicalSummary'] as Map? ?? {},
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  static const empty = UserEmergencyProfile();
}
