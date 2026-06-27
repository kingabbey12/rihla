/// Cloud-synced user profile.
class UserProfile {
  const UserProfile({
    this.name,
    this.photoUrl,
    this.email,
    this.updatedAt,
    this.createdAt,
  });

  final String? name;
  final String? photoUrl;
  final String? email;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  bool get isEmpty => name == null && photoUrl == null && email == null;

  UserProfile copyWith({
    String? name,
    String? photoUrl,
    String? email,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'photoUrl': photoUrl,
        'email': email,
        'updatedAt': updatedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String?,
      photoUrl: json['photoUrl'] as String?,
      email: json['email'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  static const empty = UserProfile();
}
