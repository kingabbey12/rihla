/// Types of emergency incidents supported by the platform.
enum EmergencyType {
  vehicleBreakdown,
  flatTire,
  batteryFailure,
  accident,
  medicalEmergency,
  fire,
  vehicleTheft,
  flood,
  sandstorm,
  lostDriver,
  dangerousRoad,
  roadObstruction,
  other,
}

extension EmergencyTypeX on EmergencyType {
  String get id => name;

  String get displayName => switch (this) {
        EmergencyType.vehicleBreakdown => 'Vehicle Breakdown',
        EmergencyType.flatTire => 'Flat Tire',
        EmergencyType.batteryFailure => 'Battery Failure',
        EmergencyType.accident => 'Accident',
        EmergencyType.medicalEmergency => 'Medical Emergency',
        EmergencyType.fire => 'Fire',
        EmergencyType.vehicleTheft => 'Vehicle Theft',
        EmergencyType.flood => 'Flood',
        EmergencyType.sandstorm => 'Sandstorm',
        EmergencyType.lostDriver => 'Lost Driver',
        EmergencyType.dangerousRoad => 'Dangerous Road',
        EmergencyType.roadObstruction => 'Road Obstruction',
        EmergencyType.other => 'Other',
      };
}
