/// User preferences synced across devices.
class UserPreferences {
  const UserPreferences({
    this.languageCode = 'en',
    this.themeMode = 'system',
    this.homePlaceId,
    this.workPlaceId,
    this.drivingPreferences = const {},
    this.navigationPreferences = const {},
    this.aiPreferences = const {},
    this.privacyPreferences = const {},
    this.updatedAt,
  });

  final String languageCode;
  final String themeMode;
  final String? homePlaceId;
  final String? workPlaceId;
  final Map<String, String> drivingPreferences;
  final Map<String, String> navigationPreferences;
  final Map<String, String> aiPreferences;
  final Map<String, String> privacyPreferences;
  final DateTime? updatedAt;

  UserPreferences copyWith({
    String? languageCode,
    String? themeMode,
    String? homePlaceId,
    String? workPlaceId,
    Map<String, String>? drivingPreferences,
    Map<String, String>? navigationPreferences,
    Map<String, String>? aiPreferences,
    Map<String, String>? privacyPreferences,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      homePlaceId: homePlaceId ?? this.homePlaceId,
      workPlaceId: workPlaceId ?? this.workPlaceId,
      drivingPreferences: drivingPreferences ?? this.drivingPreferences,
      navigationPreferences:
          navigationPreferences ?? this.navigationPreferences,
      aiPreferences: aiPreferences ?? this.aiPreferences,
      privacyPreferences: privacyPreferences ?? this.privacyPreferences,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'themeMode': themeMode,
        'homePlaceId': homePlaceId,
        'workPlaceId': workPlaceId,
        'drivingPreferences': drivingPreferences,
        'navigationPreferences': navigationPreferences,
        'aiPreferences': aiPreferences,
        'privacyPreferences': privacyPreferences,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      languageCode: json['languageCode'] as String? ?? 'en',
      themeMode: json['themeMode'] as String? ?? 'system',
      homePlaceId: json['homePlaceId'] as String?,
      workPlaceId: json['workPlaceId'] as String?,
      drivingPreferences: Map<String, String>.from(
        json['drivingPreferences'] as Map? ?? {},
      ),
      navigationPreferences: Map<String, String>.from(
        json['navigationPreferences'] as Map? ?? {},
      ),
      aiPreferences: Map<String, String>.from(
        json['aiPreferences'] as Map? ?? {},
      ),
      privacyPreferences: Map<String, String>.from(
        json['privacyPreferences'] as Map? ?? {},
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  static const defaults = UserPreferences();
}
