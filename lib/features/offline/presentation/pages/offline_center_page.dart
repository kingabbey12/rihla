import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/features/offline/data/catalog/uae_offline_regions.dart';
import 'package:rihla/features/offline/domain/entities/offline_download.dart';
import 'package:rihla/features/offline/domain/entities/offline_engine_state.dart';
import 'package:rihla/features/offline/domain/models/offline_state.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';

/// Offline Center — manage downloads, storage, and smart suggestions.
class OfflineCenterPage extends ConsumerStatefulWidget {
  const OfflineCenterPage({super.key});

  @override
  ConsumerState<OfflineCenterPage> createState() => _OfflineCenterPageState();
}

class _OfflineCenterPageState extends ConsumerState<OfflineCenterPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(offlineControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(offlineControllerProvider);
    final storage = state.storageInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(offlineControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatusCard(state: state),
            const SizedBox(height: 16),
            if (storage != null) _StorageCard(storage: storage),
            const SizedBox(height: 16),
            if (state.suggestions.isNotEmpty) ...[
              const Text('Smart Suggestions',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...state.suggestions.map(_SuggestionTile.new),
              const SizedBox(height: 16),
            ],
            if (state.downloads.isNotEmpty) ...[
              const Text('Download Queue',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...state.downloads.map((d) => _DownloadTile(download: d)),
              const SizedBox(height: 16),
            ],
            const Text('UAE Regions',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...UaeOfflineRegions.all.map(
              (region) => _RegionTile(
                regionId: region.id,
                name: region.name,
                sizeMb: region.estimatedSizeMb,
                isDownloaded: state.downloadedRegionIds.contains(region.id),
              ),
            ),
            if (storage != null && storage.downloadedRegions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Downloaded Maps',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...storage.downloadedRegions.map(
                (info) => ListTile(
                  title: Text(info.region.name),
                  subtitle: Text(
                    'v${info.installedVersion} · '
                    '${(info.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (info.isCorrupted || info.isOutdated)
                        IconButton(
                          icon: const Icon(Icons.build),
                          onPressed: () => ref
                              .read(offlineControllerProvider.notifier)
                              .repair(info.region.id),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(offlineControllerProvider.notifier)
                            .deleteRegion(info.region.id),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final OfflineState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state.engineState) {
      OfflineEngineState.online => 'Online',
      OfflineEngineState.offline => 'Offline',
      OfflineEngineState.syncing => 'Syncing',
      OfflineEngineState.downloading => 'Downloading',
      OfflineEngineState.updating => 'Updating',
      OfflineEngineState.paused => 'Paused',
      OfflineEngineState.error => 'Error',
    };
    return Card(
      child: ListTile(
        leading: Icon(
          state.isConnected ? Icons.wifi : Icons.wifi_off,
          color: state.isConnected ? Colors.green : Colors.orange,
        ),
        title: Text(label),
        subtitle: Text(
          '${state.downloadedRegionIds.length} regions downloaded',
        ),
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.storage});

  final dynamic storage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Storage',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: storage.totalBytes > 0
                  ? storage.offlineUsedBytes / storage.totalBytes
                  : 0,
            ),
            const SizedBox(height: 8),
            Text(
              'Offline: ${storage.offlineUsedMb.toStringAsFixed(1)} MB · '
              'Free: ${storage.freeMb.toStringAsFixed(0)} MB',
            ),
            if (storage.corruptedRegionIds.isNotEmpty)
              Text(
                '${storage.corruptedRegionIds.length} corrupted — tap Repair',
                style: TextStyle(color: Colors.red.shade700),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends ConsumerWidget {
  const _SuggestionTile(this.suggestion);

  final OfflineDownloadSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(suggestion.region.name),
        subtitle: Text(suggestion.reason),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => ref
                  .read(offlineControllerProvider.notifier)
                  .dismissSuggestion(suggestion.id),
              child: const Text('Dismiss'),
            ),
            FilledButton(
              onPressed: () => ref
                  .read(offlineControllerProvider.notifier)
                  .downloadRegion(suggestion.region.id),
              child: const Text('Download'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({required this.download});

  final OfflineDownload download;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(offlineControllerProvider.notifier);
    return Card(
      child: ListTile(
        title: Text(download.regionName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: download.progressPercent / 100),
            Text(
              '${download.progressPercent.toStringAsFixed(0)}% · '
              '${download.status.name}',
            ),
          ],
        ),
        trailing: _downloadActions(download, ctrl),
      ),
    );
  }

  Widget? _downloadActions(OfflineDownload d, OfflineController ctrl) {
    return switch (d.status) {
      OfflineDownloadStatus.downloading => IconButton(
          icon: const Icon(Icons.pause),
          onPressed: () => ctrl.pause(d.id),
        ),
      OfflineDownloadStatus.paused => IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () => ctrl.resume(d.id),
        ),
      OfflineDownloadStatus.failed => IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ctrl.resume(d.id),
        ),
      OfflineDownloadStatus.queued ||
      OfflineDownloadStatus.verifying =>
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => ctrl.cancel(d.id),
        ),
      _ => null,
    };
  }
}

class _RegionTile extends ConsumerWidget {
  const _RegionTile({
    required this.regionId,
    required this.name,
    required this.sizeMb,
    required this.isDownloaded,
  });

  final String regionId;
  final String name;
  final int sizeMb;
  final bool isDownloaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(name),
      subtitle: Text('~$sizeMb MB'),
      trailing: isDownloaded
          ? const Icon(Icons.check_circle, color: Colors.green)
          : FilledButton(
              onPressed: () => ref
                  .read(offlineControllerProvider.notifier)
                  .downloadRegion(regionId),
              child: const Text('Download'),
            ),
    );
  }
}
