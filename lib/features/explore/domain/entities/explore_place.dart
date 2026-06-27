import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

/// A discoverable place in the Explore ecosystem.
class ExplorePlace {
  const ExplorePlace({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.rating,
    this.reviewCount,
    this.openingHours,
    this.isOpenNow,
    this.isOpen24Hours,
    this.phone,
    this.website,
    this.photoUrl,
    this.distanceKm,
    this.etaMinutes,
    this.fuelTypes = const [],
    this.evConnectorTypes = const [],
    this.isFreeParking = false,
    this.isPaidParking = false,
    this.isAccessible = false,
    this.isFamilyFriendly = false,
    this.priceLevel,
  });

  final String id;
  final String name;
  final ExploreCategory category;
  final double latitude;
  final double longitude;
  final String address;
  final double? rating;
  final int? reviewCount;
  final String? openingHours;
  final bool? isOpenNow;
  final bool? isOpen24Hours;
  final String? phone;
  final String? website;
  final String? photoUrl;
  final double? distanceKm;
  final int? etaMinutes;
  final List<String> fuelTypes;
  final List<String> evConnectorTypes;
  final bool isFreeParking;
  final bool isPaidParking;
  final bool isAccessible;
  final bool isFamilyFriendly;
  final int? priceLevel;

  SearchPlace toSearchPlace() => SearchPlace(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        category: category.id,
      );

  JourneyEndpoint toJourneyEndpoint() => JourneyEndpoint(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        if (rating != null) 'rating': rating,
        if (reviewCount != null) 'reviewCount': reviewCount,
        if (openingHours != null) 'openingHours': openingHours,
        if (isOpenNow != null) 'isOpenNow': isOpenNow,
        if (isOpen24Hours != null) 'isOpen24Hours': isOpen24Hours,
        if (phone != null) 'phone': phone,
        if (website != null) 'website': website,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (distanceKm != null) 'distanceKm': distanceKm,
        if (etaMinutes != null) 'etaMinutes': etaMinutes,
        'fuelTypes': fuelTypes,
        'evConnectorTypes': evConnectorTypes,
        'isFreeParking': isFreeParking,
        'isPaidParking': isPaidParking,
        'isAccessible': isAccessible,
        'isFamilyFriendly': isFamilyFriendly,
        if (priceLevel != null) 'priceLevel': priceLevel,
      };

  factory ExplorePlace.fromJson(Map<String, dynamic> json) => ExplorePlace(
        id: json['id'] as String,
        name: json['name'] as String,
        category: ExploreCategory.values.byName(json['category'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String,
        rating: (json['rating'] as num?)?.toDouble(),
        reviewCount: json['reviewCount'] as int?,
        openingHours: json['openingHours'] as String?,
        isOpenNow: json['isOpenNow'] as bool?,
        isOpen24Hours: json['isOpen24Hours'] as bool?,
        phone: json['phone'] as String?,
        website: json['website'] as String?,
        photoUrl: json['photoUrl'] as String?,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        etaMinutes: json['etaMinutes'] as int?,
        fuelTypes: (json['fuelTypes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        evConnectorTypes: (json['evConnectorTypes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        isFreeParking: json['isFreeParking'] as bool? ?? false,
        isPaidParking: json['isPaidParking'] as bool? ?? false,
        isAccessible: json['isAccessible'] as bool? ?? false,
        isFamilyFriendly: json['isFamilyFriendly'] as bool? ?? false,
        priceLevel: json['priceLevel'] as int?,
      );
}
