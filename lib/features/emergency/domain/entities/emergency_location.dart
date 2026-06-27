/// Geographic location captured during an emergency event.
class EmergencyLocation {
  const EmergencyLocation({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.address,
    this.accuracyMeters,
    this.roadName,
  });

  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final String? address;
  final double? accuracyMeters;
  final String? roadName;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'capturedAt': capturedAt.toIso8601String(),
        if (address != null) 'address': address,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        if (roadName != null) 'roadName': roadName,
      };

  factory EmergencyLocation.fromJson(Map<String, dynamic> json) =>
      EmergencyLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        address: json['address'] as String?,
        accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
        roadName: json['roadName'] as String?,
      );
}
