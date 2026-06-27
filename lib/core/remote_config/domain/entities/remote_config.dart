/// Runtime feature flags and operational toggles for beta/production.
///
/// Merged from compile-time defaults ([RemoteConfig.defaults]) and any
/// fetched remote overrides. Features must read flags via [remoteConfigProvider]
/// — never from hard-coded compile-time constants directly.
class RemoteConfig {
  const RemoteConfig({
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.aiEnabled = true,
    this.emergencyEnabled = true,
    this.exploreEnabled = true,
    this.offlineEnabled = true,
    this.cloudSyncEnabled = true,
    this.betaFeedbackEnabled = true,
    this.uaeIntelligenceEnabled = true,
    this.regionalRollout = const ['AE'],
    this.killSwitches = const {},
    this.rawVersion = 0,
  });

  final bool maintenanceMode;
  final String? maintenanceMessage;
  final bool aiEnabled;
  final bool emergencyEnabled;
  final bool exploreEnabled;
  final bool offlineEnabled;
  final bool cloudSyncEnabled;
  final bool betaFeedbackEnabled;
  final bool uaeIntelligenceEnabled;

  /// ISO country codes where the beta is active (e.g. `AE` for UAE).
  final List<String> regionalRollout;
  final Map<String, bool> killSwitches;
  final int rawVersion;

  /// Safe defaults when remote fetch fails or is unavailable.
  static RemoteConfig defaults({
    bool aiEnabled = true,
    bool cloudSyncEnabled = false,
  }) =>
      RemoteConfig(
        aiEnabled: aiEnabled,
        cloudSyncEnabled: cloudSyncEnabled,
      );

  bool isKillSwitchActive(String key) => killSwitches[key] == true;

  bool isRegionEnabled(String countryCode) =>
      regionalRollout.isEmpty ||
      regionalRollout.contains(countryCode.toUpperCase());

  RemoteConfig copyWith({
    bool? maintenanceMode,
    String? maintenanceMessage,
    bool? aiEnabled,
    bool? emergencyEnabled,
    bool? exploreEnabled,
    bool? offlineEnabled,
    bool? cloudSyncEnabled,
    bool? betaFeedbackEnabled,
    bool? uaeIntelligenceEnabled,
    List<String>? regionalRollout,
    Map<String, bool>? killSwitches,
    int? rawVersion,
  }) =>
      RemoteConfig(
        maintenanceMode: maintenanceMode ?? this.maintenanceMode,
        maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
        aiEnabled: aiEnabled ?? this.aiEnabled,
        emergencyEnabled: emergencyEnabled ?? this.emergencyEnabled,
        exploreEnabled: exploreEnabled ?? this.exploreEnabled,
        offlineEnabled: offlineEnabled ?? this.offlineEnabled,
        cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
        betaFeedbackEnabled: betaFeedbackEnabled ?? this.betaFeedbackEnabled,
        uaeIntelligenceEnabled:
            uaeIntelligenceEnabled ?? this.uaeIntelligenceEnabled,
        regionalRollout: regionalRollout ?? this.regionalRollout,
        killSwitches: killSwitches ?? this.killSwitches,
        rawVersion: rawVersion ?? this.rawVersion,
      );

  Map<String, dynamic> toJson() => {
        'maintenanceMode': maintenanceMode,
        'maintenanceMessage': maintenanceMessage,
        'aiEnabled': aiEnabled,
        'emergencyEnabled': emergencyEnabled,
        'exploreEnabled': exploreEnabled,
        'offlineEnabled': offlineEnabled,
        'cloudSyncEnabled': cloudSyncEnabled,
        'betaFeedbackEnabled': betaFeedbackEnabled,
        'uaeIntelligenceEnabled': uaeIntelligenceEnabled,
        'regionalRollout': regionalRollout,
        'killSwitches': killSwitches,
        'rawVersion': rawVersion,
      };

  factory RemoteConfig.fromJson(Map<String, dynamic> json) => RemoteConfig(
        maintenanceMode: json['maintenanceMode'] as bool? ?? false,
        maintenanceMessage: json['maintenanceMessage'] as String?,
        aiEnabled: json['aiEnabled'] as bool? ?? true,
        emergencyEnabled: json['emergencyEnabled'] as bool? ?? true,
        exploreEnabled: json['exploreEnabled'] as bool? ?? true,
        offlineEnabled: json['offlineEnabled'] as bool? ?? true,
        cloudSyncEnabled: json['cloudSyncEnabled'] as bool? ?? true,
        betaFeedbackEnabled: json['betaFeedbackEnabled'] as bool? ?? true,
        uaeIntelligenceEnabled: json['uaeIntelligenceEnabled'] as bool? ?? true,
        regionalRollout: (json['regionalRollout'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const ['AE'],
        killSwitches: Map<String, bool>.from(
          (json['killSwitches'] as Map<String, dynamic>?) ?? {},
        ),
        rawVersion: json['rawVersion'] as int? ?? 0,
      );
}
