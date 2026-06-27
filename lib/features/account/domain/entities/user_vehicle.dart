/// Cloud-synced vehicle profile.
class UserVehicle {
  const UserVehicle({
    this.make,
    this.model,
    this.year,
    this.licensePlate,
    this.fuelType,
    this.insuranceProvider,
    this.roadsideMembership,
    this.updatedAt,
  });

  final String? make;
  final String? model;
  final int? year;
  final String? licensePlate;
  final String? fuelType;
  final String? insuranceProvider;
  final String? roadsideMembership;
  final DateTime? updatedAt;

  bool get isEmpty =>
      make == null &&
      model == null &&
      year == null &&
      licensePlate == null;

  UserVehicle copyWith({
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? fuelType,
    String? insuranceProvider,
    String? roadsideMembership,
    DateTime? updatedAt,
  }) {
    return UserVehicle(
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      fuelType: fuelType ?? this.fuelType,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      roadsideMembership: roadsideMembership ?? this.roadsideMembership,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'make': make,
        'model': model,
        'year': year,
        'licensePlate': licensePlate,
        'fuelType': fuelType,
        'insuranceProvider': insuranceProvider,
        'roadsideMembership': roadsideMembership,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory UserVehicle.fromJson(Map<String, dynamic> json) {
    return UserVehicle(
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: json['year'] as int?,
      licensePlate: json['licensePlate'] as String?,
      fuelType: json['fuelType'] as String?,
      insuranceProvider: json['insuranceProvider'] as String?,
      roadsideMembership: json['roadsideMembership'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  static const empty = UserVehicle();
}
