/// A searchable geographic place.
class SearchPlace {
  const SearchPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.category,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  /// Optional category key (e.g. airport, landmark, mall).
  final String? category;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (category != null) 'category': category,
      };

  factory SearchPlace.fromJson(Map<String, dynamic> json) => SearchPlace(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        category: json['category'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchPlace &&
          id == other.id &&
          name == other.name &&
          address == other.address &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          category == other.category;

  @override
  int get hashCode =>
      Object.hash(id, name, address, latitude, longitude, category);

  @override
  String toString() => 'SearchPlace($name @ $latitude, $longitude)';
}
