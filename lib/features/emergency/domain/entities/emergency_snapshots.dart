/// Snapshots captured at the time of an emergency event.
class EmergencySnapshots {
  const EmergencySnapshots({
    this.navigationSessionId,
    this.journeyDestination,
    this.safetyScore,
    this.safetyHazards = const [],
    this.routeDistanceKm,
    this.etaMinutes,
    this.speedKmh,
  });

  final String? navigationSessionId;
  final String? journeyDestination;
  final double? safetyScore;
  final List<String> safetyHazards;
  final double? routeDistanceKm;
  final int? etaMinutes;
  final double? speedKmh;

  Map<String, dynamic> toJson() => {
        if (navigationSessionId != null)
          'navigationSessionId': navigationSessionId,
        if (journeyDestination != null) 'journeyDestination': journeyDestination,
        if (safetyScore != null) 'safetyScore': safetyScore,
        'safetyHazards': safetyHazards,
        if (routeDistanceKm != null) 'routeDistanceKm': routeDistanceKm,
        if (etaMinutes != null) 'etaMinutes': etaMinutes,
        if (speedKmh != null) 'speedKmh': speedKmh,
      };

  factory EmergencySnapshots.fromJson(Map<String, dynamic> json) =>
      EmergencySnapshots(
        navigationSessionId: json['navigationSessionId'] as String?,
        journeyDestination: json['journeyDestination'] as String?,
        safetyScore: (json['safetyScore'] as num?)?.toDouble(),
        safetyHazards: (json['safetyHazards'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        routeDistanceKm: (json['routeDistanceKm'] as num?)?.toDouble(),
        etaMinutes: json['etaMinutes'] as int?,
        speedKmh: (json['speedKmh'] as num?)?.toDouble(),
      );
}
