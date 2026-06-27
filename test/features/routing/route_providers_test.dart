import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/routing/data/repositories/route_repository_impl.dart';
import 'package:rihla/features/routing/data/services/mock_route_service.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';
import 'package:rihla/features/routing/domain/errors/route_failure.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/domain/services/route_service.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

void main() {
  const origin = RoutePoint(latitude: 24.7136, longitude: 46.6753);
  const destination = RoutePoint(latitude: 24.7113, longitude: 46.6743);

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        routeServiceProvider.overrideWith((ref) => MockRouteService()),
        routeRepositoryProvider.overrideWith(
          (ref) => RouteRepositoryImpl(ref.watch(routeServiceProvider)),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('fetchRoutes transitions to ready', () async {
    await container.read(routeControllerProvider.notifier).fetchRoutes(
          const RouteRequest(origin: origin, destination: destination),
        );
    expect(container.read(routeControllerProvider), isA<RouteReady>());
  });

  test('selectRoute transitions to selected', () async {
    final notifier = container.read(routeControllerProvider.notifier);
    await notifier.fetchRoutes(
      const RouteRequest(origin: origin, destination: destination),
    );
    final ready = container.read(routeControllerProvider) as RouteReady;
    notifier.selectRoute(ready.result.routes.first.id);
    expect(container.read(routeControllerProvider), isA<RouteSelected>());
  });

  test('confirmSelection transitions to confirmed', () async {
    final notifier = container.read(routeControllerProvider.notifier);
    await notifier.fetchRoutes(
      const RouteRequest(origin: origin, destination: destination),
    );
    final ready = container.read(routeControllerProvider) as RouteReady;
    notifier.selectRoute(ready.result.routes.first.id);
    notifier.confirmSelection();
    expect(container.read(routeControllerProvider), isA<RouteConfirmed>());
  });

  test('retry re-fetches after error', () async {
    var calls = 0;
    final retryContainer = ProviderContainer(
      overrides: [
        routeServiceProvider.overrideWith(
          (ref) => _FailingThenOkService(onCall: () => calls++),
        ),
        routeRepositoryProvider.overrideWith(
          (ref) => RouteRepositoryImpl(ref.watch(routeServiceProvider)),
        ),
      ],
    );
    addTearDown(retryContainer.dispose);

    final notifier = retryContainer.read(routeControllerProvider.notifier);
    await notifier.fetchRoutes(
      const RouteRequest(origin: origin, destination: destination),
    );
    expect(retryContainer.read(routeControllerProvider), isA<RouteError>());
    await notifier.retry();
    expect(retryContainer.read(routeControllerProvider), isA<RouteReady>());
    expect(calls, 2);
  });
}

class _FailingThenOkService implements RouteService {
  _FailingThenOkService({required this.onCall});

  final void Function() onCall;
  final _mock = MockRouteService(simulatedDelay: Duration.zero);
  var _fail = true;

  @override
  Future<RouteResult> calculateRoutes(RouteRequest request) async {
    onCall();
    if (_fail) {
      _fail = false;
      throw const RouteNetworkFailure('test');
    }
    return _mock.calculateRoutes(request);
  }
}
