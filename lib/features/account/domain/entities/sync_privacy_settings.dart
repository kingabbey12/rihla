import 'package:rihla/features/account/domain/entities/sync_category.dart';

/// Per-category cloud sync privacy settings.
class SyncPrivacySettings {
  const SyncPrivacySettings({this.enabled = const {}});

  final Map<SyncCategory, bool> enabled;

  bool isEnabled(SyncCategory category) {
    if (!category.hasPrivacyToggle) return true;
    return enabled[category] ?? _defaultFor(category);
  }

  static bool _defaultFor(SyncCategory category) => switch (category) {
        SyncCategory.medicalProfile => false,
        SyncCategory.locationHistory => false,
        _ => true,
      };

  SyncPrivacySettings copyWith({Map<SyncCategory, bool>? enabled}) {
    return SyncPrivacySettings(enabled: enabled ?? this.enabled);
  }

  SyncPrivacySettings withCategory(SyncCategory category, bool value) {
    return copyWith(enabled: {...enabled, category: value});
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled.map((k, v) => MapEntry(k.name, v)),
      };

  factory SyncPrivacySettings.fromJson(Map<String, dynamic> json) {
    final raw = json['enabled'] as Map<String, dynamic>? ?? {};
    return SyncPrivacySettings(
      enabled: raw.map(
        (key, value) => MapEntry(
          SyncCategory.values.firstWhere((c) => c.name == key),
          value as bool,
        ),
      ),
    );
  }

  static const defaults = SyncPrivacySettings();
}
