import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';

/// Abstraction for roadside assistance providers (future integration).
abstract class RoadsideProvider {
  Future<String> submitRequest(RoadsideRequest request);
  Future<RoadsideRequestStatus> checkStatus(String providerReference);
}

/// Stub provider for Phase 14 — returns a local reference.
class StubRoadsideProvider implements RoadsideProvider {
  @override
  Future<String> submitRequest(RoadsideRequest request) async {
    return 'stub_${request.id}';
  }

  @override
  Future<RoadsideRequestStatus> checkStatus(String providerReference) async {
    return RoadsideRequestStatus.submitted;
  }
}
