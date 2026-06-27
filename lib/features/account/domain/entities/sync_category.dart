/// Categories of data synchronized to the cloud.
enum SyncCategory {
  favorites,
  savedPlaces,
  collections,
  journeyHistory,
  emergencyContacts,
  vehicleProfile,
  medicalProfile,
  drivingStatistics,
  downloadedPreferences,
  userSettings,
  aiConversations,
  journeyReviews,
  searchHistory,
  locationHistory,
}

extension SyncCategoryX on SyncCategory {
  String get displayName => switch (this) {
        SyncCategory.favorites => 'Favorites',
        SyncCategory.savedPlaces => 'Saved Places',
        SyncCategory.collections => 'Collections',
        SyncCategory.journeyHistory => 'Journey History',
        SyncCategory.emergencyContacts => 'Emergency Contacts',
        SyncCategory.vehicleProfile => 'Vehicle Profile',
        SyncCategory.medicalProfile => 'Medical Profile',
        SyncCategory.drivingStatistics => 'Driving Statistics',
        SyncCategory.downloadedPreferences => 'Downloaded Preferences',
        SyncCategory.userSettings => 'User Settings',
        SyncCategory.aiConversations => 'AI Conversations',
        SyncCategory.journeyReviews => 'Journey Reviews',
        SyncCategory.searchHistory => 'Search History',
        SyncCategory.locationHistory => 'Location History',
      };

  /// Categories with individual privacy toggles.
  bool get hasPrivacyToggle => switch (this) {
        SyncCategory.medicalProfile ||
        SyncCategory.journeyHistory ||
        SyncCategory.aiConversations ||
        SyncCategory.drivingStatistics ||
        SyncCategory.emergencyContacts ||
        SyncCategory.locationHistory =>
          true,
        _ => false,
      };
}
