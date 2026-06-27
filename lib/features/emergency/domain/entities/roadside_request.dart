import 'package:rihla/features/emergency/domain/entities/emergency_location.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';

/// Roadside assistance request types.
enum RoadsideRequestType {
  towTruck,
  batteryBoost,
  flatTire,
  fuelDelivery,
  lockout,
  mechanicalFailure,
}

extension RoadsideRequestTypeX on RoadsideRequestType {
  String get displayName => switch (this) {
        RoadsideRequestType.towTruck => 'Tow Truck',
        RoadsideRequestType.batteryBoost => 'Battery Boost',
        RoadsideRequestType.flatTire => 'Flat Tire',
        RoadsideRequestType.fuelDelivery => 'Fuel Delivery',
        RoadsideRequestType.lockout => 'Lockout',
        RoadsideRequestType.mechanicalFailure => 'Mechanical Failure',
      };
}

/// Status of a roadside assistance request.
enum RoadsideRequestStatus {
  pending,
  queued,
  submitted,
  dispatched,
  completed,
  cancelled,
}

/// A roadside assistance request.
class RoadsideRequest {
  const RoadsideRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.location,
    required this.createdAt,
    this.vehicleProfile,
    this.notes,
    this.providerReference,
    this.syncedAt,
  });

  final String id;
  final RoadsideRequestType type;
  final RoadsideRequestStatus status;
  final EmergencyLocation location;
  final DateTime createdAt;
  final EmergencyVehicleProfile? vehicleProfile;
  final String? notes;
  final String? providerReference;
  final DateTime? syncedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'status': status.name,
        'location': location.toJson(),
        'createdAt': createdAt.toIso8601String(),
        if (vehicleProfile != null) 'vehicleProfile': vehicleProfile!.toJson(),
        if (notes != null) 'notes': notes,
        if (providerReference != null) 'providerReference': providerReference,
        if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
      };

  factory RoadsideRequest.fromJson(Map<String, dynamic> json) => RoadsideRequest(
        id: json['id'] as String,
        type: RoadsideRequestType.values.byName(json['type'] as String),
        status:
            RoadsideRequestStatus.values.byName(json['status'] as String),
        location: EmergencyLocation.fromJson(
          json['location'] as Map<String, dynamic>,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        vehicleProfile: json['vehicleProfile'] != null
            ? EmergencyVehicleProfile.fromJson(
                json['vehicleProfile'] as Map<String, dynamic>,
              )
            : null,
        notes: json['notes'] as String?,
        providerReference: json['providerReference'] as String?,
        syncedAt: json['syncedAt'] != null
            ? DateTime.parse(json['syncedAt'] as String)
            : null,
      );

  RoadsideRequest copyWith({
    RoadsideRequestStatus? status,
    String? providerReference,
    DateTime? syncedAt,
  }) =>
      RoadsideRequest(
        id: id,
        type: type,
        status: status ?? this.status,
        location: location,
        createdAt: createdAt,
        vehicleProfile: vehicleProfile,
        notes: notes,
        providerReference: providerReference ?? this.providerReference,
        syncedAt: syncedAt ?? this.syncedAt,
      );
}
