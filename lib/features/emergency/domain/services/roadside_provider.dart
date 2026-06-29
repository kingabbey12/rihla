import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';

/// Abstraction for roadside assistance providers.
abstract class RoadsideProvider {
  Future<String> submitRequest(RoadsideRequest request);
  Future<RoadsideRequestStatus> checkStatus(String providerReference);
}

/// Fails explicitly when no real UAE roadside provider is configured.
class UnconfiguredRoadsideProvider implements RoadsideProvider {
  @override
  Future<String> submitRequest(RoadsideRequest request) async {
    throw StateError(
      'Roadside assistance provider is not configured. '
      'Configure a UAE dispatch integration before submitting requests.',
    );
  }

  @override
  Future<RoadsideRequestStatus> checkStatus(String providerReference) async {
    throw StateError('Roadside assistance provider is not configured.');
  }
}
