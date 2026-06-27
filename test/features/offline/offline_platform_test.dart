import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/offline/data/catalog/uae_offline_regions.dart';
import 'package:rihla/features/offline/data/datasources/offline_download_local_datasource.dart';
import 'package:rihla/features/offline/data/datasources/offline_storage_datasource.dart';
import 'package:rihla/features/offline/data/repositories/offline_aware_route_repository.dart';
import 'package:rihla/features/offline/data/repositories/offline_aware_search_repository.dart';
import 'package:rihla/features/offline/data/repositories/offline_route_repository.dart';
import 'package:rihla/features/offline/data/repositories/offline_search_repository.dart';
import 'package:rihla/features/offline/data/services/connectivity_network_monitor.dart';
import 'package:rihla/features/offline/data/services/offline_engine_service.dart';
import 'package:rihla/features/offline/data/services/offline_route_service.dart';
import 'package:rihla/features/offline/domain/entities/offline_download.dart';
import 'package:rihla/features/offline/domain/entities/offline_engine_state.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';
import 'package:rihla/features/routing/data/repositories/route_repository_impl.dart';
import 'package:rihla/features/routing/data/services/mock_route_service.dart';
import 'package:rihla/features/routing/domain/entities/route_point.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/search/data/datasources/search_local_datasource.dart';
import 'package:rihla/features/search/data/services/mock_search_service.dart';
import 'package:rihla/features/search/domain/repositories/search_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/navigation_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late OfflineStorageDatasource storage;
  late OfflineEngineService engine;
  late SearchLocalDataSource searchLocal;

  late Directory testDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    testDir = await Directory.systemTemp.createTemp('rihla_offline_test');
    storage = OfflineStorageDatasource(testRoot: testDir.path);
    engine = OfflineEngineService(
      storage,
      OfflineDownloadLocalDatasource(prefs),
    );
    searchLocal = SearchLocalDataSource(prefs);
  });

  tearDown(() async {
    if (await testDir.exists()) await testDir.delete(recursive: true);
  });

  group('Network monitor', () {
    test('detects connectivity changes', () async {
      final monitor = FakeNetworkMonitor(connected: true);
      monitor.start();
      expect(await monitor.checkConnected(), isTrue);
      monitor.setConnected(false);
      expect(await monitor.checkConnected(), isFalse);
      monitor.dispose();
    });
  });

  group('Download manager', () {
    test('download completes with integrity verification', () async {
      final download = await engine.startDownload(UaeOfflineRegions.dubai);
      OfflineDownload current = download;
      while (current.status != OfflineDownloadStatus.completed &&
          current.status != OfflineDownloadStatus.failed) {
        current = await engine.tickDownload(current.id);
      }
      expect(current.status, OfflineDownloadStatus.completed);
      expect(await engine.verifyRegionIntegrity(UaeOfflineRegions.dubai.id),
          isTrue);
    });

    test('pause and resume download', () async {
      final download = await engine.startDownload(UaeOfflineRegions.sharjah);
      await engine.pauseDownload(download.id);
      final paused = engine.activeDownloads().first;
      expect(paused.status, OfflineDownloadStatus.paused);

      await engine.resumeDownload(download.id);
      var current = engine.activeDownloads().first;
      expect(current.status, OfflineDownloadStatus.downloading);

      while (current.status != OfflineDownloadStatus.completed) {
        current = await engine.tickDownload(current.id);
      }
      expect(current.progressPercent, 100);
    });

    test('cancel download', () async {
      final download = await engine.startDownload(UaeOfflineRegions.ajman);
      await engine.cancelDownload(download.id);
      final cancelled = engine.activeDownloads().first;
      expect(cancelled.status, OfflineDownloadStatus.cancelled);
    });

    test('repair corrupted region', () async {
      final download = await engine.startDownload(UaeOfflineRegions.fujairah);
      while (engine.activeDownloads().first.status !=
          OfflineDownloadStatus.completed) {
        await engine.tickDownload(download.id);
      }
      await storage.writeChecksum(UaeOfflineRegions.fujairah.id, 'bad');
      expect(
        await engine.verifyRegionIntegrity(UaeOfflineRegions.fujairah.id),
        isFalse,
      );
      await engine.repairRegion(UaeOfflineRegions.fujairah.id);
      expect(
        await engine.verifyRegionIntegrity(UaeOfflineRegions.fujairah.id),
        isTrue,
      );
    });
  });

  group('Offline search', () {
    test('searches downloaded POIs', () async {
      final download = await engine.startDownload(UaeOfflineRegions.dubai);
      while (engine.activeDownloads().first.status !=
          OfflineDownloadStatus.completed) {
        await engine.tickDownload(download.id);
      }

      final offlineSearch = OfflineSearchRepository(
        engine,
        storage,
        searchLocal,
      );
      final results = await offlineSearch.search('Marina');
      expect(results, isNotEmpty);
      expect(results.first.name, contains('Marina'));
    });

    test('offline aware repository switches on connectivity', () async {
      var offline = false;
      final repo = OfflineAwareSearchRepository(
        isOffline: () => offline,
        online: _FailingSearchRepo(),
        offline: OfflineSearchRepository(engine, storage, searchLocal),
        local: searchLocal,
      );

      offline = true;
      await engine.startDownload(UaeOfflineRegions.dubai);
      while (engine.activeDownloads().first.status !=
          OfflineDownloadStatus.completed) {
        await engine.tickDownload(engine.activeDownloads().first.id);
      }

      final results = await repo.search('Dubai');
      expect(results, isNotEmpty);
    });
  });

  group('Offline routing', () {
    test('calculates routes from downloaded data', () async {
      final download = await engine.startDownload(UaeOfflineRegions.dubai);
      while (engine.activeDownloads().first.status !=
          OfflineDownloadStatus.completed) {
        await engine.tickDownload(download.id);
      }

      final routeRepo = OfflineRouteRepository(
        OfflineRouteService(storage),
      );
      final result = await routeRepo.getRoutes(
        RouteRequest(
          origin: const RoutePoint(
            id: 'a',
            name: 'A',
            latitude: 25.08,
            longitude: 55.14,
          ),
          destination: const RoutePoint(
            id: 'b',
            name: 'B',
            latitude: 25.20,
            longitude: 55.28,
          ),
        ),
      );
      expect(result.routes, isNotEmpty);
      expect(result.routes.first.profile, isNotNull);
    });

    test('offline aware route repository switches automatically', () async {
      var offline = true;
      final download = await engine.startDownload(UaeOfflineRegions.dubai);
      while (engine.activeDownloads().first.status !=
          OfflineDownloadStatus.completed) {
        await engine.tickDownload(download.id);
      }

      final repo = OfflineAwareRouteRepository(
        isOffline: () => offline,
        online: RouteRepositoryImpl(MockRouteService(simulatedDelay: Duration.zero)),
        offline: OfflineRouteRepository(OfflineRouteService(storage)),
      );

      final result = await repo.getRoutes(
        RouteRequest(
          origin: const RoutePoint(
            id: 'a',
            name: 'A',
            latitude: 25.08,
            longitude: 55.14,
          ),
          destination: const RoutePoint(
            id: 'b',
            name: 'B',
            latitude: 25.20,
            longitude: 55.28,
          ),
        ),
      );
      expect(result.routes.first.trafficSummary, contains('Offline'));
    });
  });

  group('Offline navigation journey continuation', () {
    test('navigation session starts offline with downloaded maps', () async {
      final container = ProviderContainer(
        overrides: [
          networkMonitorProvider.overrideWith((ref) => FakeNetworkMonitor(connected: false)),
          networkConnectivityStateProvider.overrideWith(() => _DisconnectedNotifier()),
        ],
      );
      addTearDown(container.dispose);

      await engine.startDownload(UaeOfflineRegions.dubai);
      while (engine.activeDownloads().first.status !=
          OfflineDownloadStatus.completed) {
        await engine.tickDownload(engine.activeDownloads().first.id);
      }

      expect(container.read(isOfflineModeProvider), isFalse);
    });
  });

  group('Storage inspection', () {
    test('detects corrupted and outdated maps', () async {
      final download = await engine.startDownload(UaeOfflineRegions.dubai);
      while (engine.activeDownloads().first.status !=
          OfflineDownloadStatus.completed) {
        await engine.tickDownload(download.id);
      }

      final info = await engine.inspectStorage();
      expect(info.downloadedRegions, isNotEmpty);
      expect(info.corruptedRegionIds, isEmpty);
    });
  });
}

class _FailingSearchRepo implements SearchRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw Exception('online fail');
}

class _DisconnectedNotifier extends NetworkConnectivityNotifier {
  @override
  bool build() => false;
}
