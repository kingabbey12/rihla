import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

/// Maps search places to journey endpoints.
extension SearchPlaceJourneyX on SearchPlace {
  JourneyEndpoint toJourneyEndpoint() => JourneyEndpoint(
        id: id,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
}

/// Default mock origin when GPS is unavailable (central Riyadh).
const JourneyEndpoint kDefaultJourneyOrigin = JourneyEndpoint(
  id: 'current_location',
  name: 'Current Location',
  address: 'Riyadh, Saudi Arabia',
  latitude: 24.7136,
  longitude: 46.6753,
);
