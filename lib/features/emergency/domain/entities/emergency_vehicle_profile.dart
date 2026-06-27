/// On-device vehicle profile for emergency and roadside assistance.
class EmergencyVehicleProfile {
  const EmergencyVehicleProfile({
    this.make,
    this.model,
    this.year,
    this.fuelType,
    this.evType,
    this.color,
    this.licensePlate,
    this.insuranceProvider,
    this.roadsideMembership,
  });

  final String? make;
  final String? model;
  final int? year;
  final String? fuelType;
  final String? evType;
  final String? color;
  final String? licensePlate;
  final String? insuranceProvider;
  final String? roadsideMembership;

  static const empty = EmergencyVehicleProfile();

  bool get isEmpty =>
      make == null &&
      model == null &&
      year == null &&
      licensePlate == null;

  String get displayName {
    final parts = <String>[];
    if (make != null) parts.add(make!);
    if (model != null) parts.add(model!);
    if (year != null) parts.add(year.toString());
    return parts.isEmpty ? 'Vehicle' : parts.join(' ');
  }

  Map<String, dynamic> toJson() => {
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (year != null) 'year': year,
        if (fuelType != null) 'fuelType': fuelType,
        if (evType != null) 'evType': evType,
        if (color != null) 'color': color,
        if (licensePlate != null) 'licensePlate': licensePlate,
        if (insuranceProvider != null) 'insuranceProvider': insuranceProvider,
        if (roadsideMembership != null)
          'roadsideMembership': roadsideMembership,
      };

  factory EmergencyVehicleProfile.fromJson(Map<String, dynamic> json) =>
      EmergencyVehicleProfile(
        make: json['make'] as String?,
        model: json['model'] as String?,
        year: json['year'] as int?,
        fuelType: json['fuelType'] as String?,
        evType: json['evType'] as String?,
        color: json['color'] as String?,
        licensePlate: json['licensePlate'] as String?,
        insuranceProvider: json['insuranceProvider'] as String?,
        roadsideMembership: json['roadsideMembership'] as String?,
      );

  EmergencyVehicleProfile copyWith({
    String? make,
    String? model,
    int? year,
    String? fuelType,
    String? evType,
    String? color,
    String? licensePlate,
    String? insuranceProvider,
    String? roadsideMembership,
  }) =>
      EmergencyVehicleProfile(
        make: make ?? this.make,
        model: model ?? this.model,
        year: year ?? this.year,
        fuelType: fuelType ?? this.fuelType,
        evType: evType ?? this.evType,
        color: color ?? this.color,
        licensePlate: licensePlate ?? this.licensePlate,
        insuranceProvider: insuranceProvider ?? this.insuranceProvider,
        roadsideMembership: roadsideMembership ?? this.roadsideMembership,
      );
}
