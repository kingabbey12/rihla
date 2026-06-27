import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/routing/data/mappers/valhalla_route_mapper.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';

void main() {
  test('maps Valhalla response with alternates', () {
    final json = {
      'trip': {
        'summary': {'length': 5.2, 'time': 720},
        'legs': [
          {'shape': '_p~iF~ps|U_ulLnnqC_mqNvxq`@'},
        ],
      },
      'alternates': [
        {
          'trip': {
            'summary': {'length': 6.1, 'time': 680},
            'legs': [
              {'shape': '_p~iF~ps|U_ulLnnqC_mqNvxq`@'},
            ],
          },
        },
      ],
    };

    final result = ValhallaRouteMapper.fromResponse(
      json,
      profiles: RouteProfile.values,
    );

    expect(result.routes, isNotEmpty);
    expect(result.routes.first.distanceKm, 5.2);
    expect(result.routes.first.durationSeconds, 720);
    expect(result.primaryRouteId, isNotNull);
  });
}
