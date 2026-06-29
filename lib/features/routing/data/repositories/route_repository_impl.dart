import 'package:rihla/core/geo/coordinate_validation.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';
import 'package:rihla/features/routing/domain/errors/route_failure.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/domain/repositories/route_repository.dart';
import 'package:rihla/features/routing/domain/services/route_service.dart';

class RouteRepositoryImpl implements RouteRepository {
  RouteRepositoryImpl(this._service);

  final RouteService _service;

  @override
  Future<RouteResult> getRoutes(RouteRequest request) async {
    if (request.allPoints.length < 2) {
      throw const RouteEmptyFailure();
    }

    // Reject invalid coordinates before hitting the network — a NaN/null/zero
    // value produces an opaque server error otherwise.
    for (final point in request.allPoints) {
      final reason = _invalidReason(point);
      if (reason != null) {
        throw RouteUnknownFailure('Invalid coordinate ($reason).');
      }
    }

    try {
      final result = await _service.calculateRoutes(request);
      if (result.routes.isEmpty) throw const RouteEmptyFailure();
      return result;
    } on RouteFailure {
      rethrow;
    } catch (e) {
      throw RouteUnknownFailure(e.toString());
    }
  }

  String? _invalidReason(RoutePoint point) =>
      CoordinateValidation.invalidReason(point.latitude, point.longitude);
}
