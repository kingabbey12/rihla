/// Category of emergency contact.
enum EmergencyContactCategory {
  trusted,
  family,
  friend,
  doctor,
  roadsideAssistance,
  insurance,
  favoriteGarage,
  favoriteHospital,
}

extension EmergencyContactCategoryX on EmergencyContactCategory {
  String get displayName => switch (this) {
        EmergencyContactCategory.trusted => 'Trusted Contact',
        EmergencyContactCategory.family => 'Family',
        EmergencyContactCategory.friend => 'Friend',
        EmergencyContactCategory.doctor => 'Doctor',
        EmergencyContactCategory.roadsideAssistance => 'Roadside Assistance',
        EmergencyContactCategory.insurance => 'Insurance',
        EmergencyContactCategory.favoriteGarage => 'Favorite Garage',
        EmergencyContactCategory.favoriteHospital => 'Favorite Hospital',
      };
}

/// An emergency contact stored on-device.
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.category,
    this.priority = 0,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String phone;
  final EmergencyContactCategory category;
  final int priority;
  final bool isFavorite;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'category': category.name,
        'priority': priority,
        'isFavorite': isFavorite,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        category: EmergencyContactCategory.values
            .byName(json['category'] as String),
        priority: json['priority'] as int? ?? 0,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  EmergencyContact copyWith({
    String? name,
    String? phone,
    EmergencyContactCategory? category,
    int? priority,
    bool? isFavorite,
  }) =>
      EmergencyContact(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}
