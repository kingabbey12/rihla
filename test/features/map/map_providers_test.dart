import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/map/domain/entities/map_camera.dart';
import 'package:rihla/features/map/domain/entities/map_style_variant.dart';
import 'package:rihla/features/map/domain/models/map_view_status.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('map style variant notifier updates only on change', () {
    expect(container.read(mapStyleVariantProvider), MapStyleVariant.light);
    container
        .read(mapStyleVariantProvider.notifier)
        .setVariant(MapStyleVariant.dark);
    expect(container.read(mapStyleVariantProvider), MapStyleVariant.dark);
  });

  test('camera notifier defaults to initial then updates', () {
    expect(container.read(mapCameraProvider), MapCamera.initial);
    const next = MapCamera(latitude: 1, longitude: 2, zoom: 9);
    container.read(mapCameraProvider.notifier).update(next);
    expect(container.read(mapCameraProvider), next);
  });

  test('view status defaults to initializing', () {
    expect(container.read(mapViewStatusProvider), isA<MapInitializing>());
    container.read(mapViewStatusProvider.notifier).set(const MapReady());
    expect(container.read(mapViewStatusProvider), isA<MapReady>());
  });

  test('location unavailable banner toggles', () {
    expect(container.read(mapLocationUnavailableProvider), isFalse);
    container.read(mapLocationUnavailableProvider.notifier).show();
    expect(container.read(mapLocationUnavailableProvider), isTrue);
    container.read(mapLocationUnavailableProvider.notifier).dismiss();
    expect(container.read(mapLocationUnavailableProvider), isFalse);
  });

  test('recreate and retry notifiers increment', () {
    expect(container.read(mapRecreateProvider), 0);
    container.read(mapRecreateProvider.notifier).bump();
    expect(container.read(mapRecreateProvider), 1);

    expect(container.read(mapLocationRetryProvider), 0);
    container.read(mapLocationRetryProvider.notifier).request();
    expect(container.read(mapLocationRetryProvider), 1);
  });
}
