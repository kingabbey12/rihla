import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:rihla/features/offline/domain/entities/offline_region.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

/// File-system access for offline map packages.
class OfflineStorageDatasource {
  OfflineStorageDatasource({String? testRoot}) : _testRoot = testRoot;

  final String? _testRoot;

  static const manifestFile = 'manifest.json';
  static const poisFile = 'pois.json';
  static const routingFile = 'routing.json';
  static const checksumFile = 'checksum.sha256';

  Future<Directory> get root async {
    if (_testRoot != null) {
      final dir = Directory(_testRoot!);
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/rihla_offline');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> regionDir(String regionId) async {
    final dir = Directory('${(await root).path}/$regionId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> writeManifest(OfflineRegion region) async {
    final dir = await regionDir(region.id);
    final file = File('${dir.path}/$manifestFile');
    await file.writeAsString(jsonEncode(region.toJson()));
  }

  Future<OfflineRegion?> readManifest(String regionId) async {
    final file = File('${(await regionDir(regionId)).path}/$manifestFile');
    if (!await file.exists()) return null;
    return OfflineRegion.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
  }

  Future<void> writePois(String regionId, List<SearchPlace> pois) async {
    final dir = await regionDir(regionId);
    final file = File('${dir.path}/$poisFile');
    await file.writeAsString(
      jsonEncode(pois.map((p) => p.toJson()).toList()),
    );
  }

  Future<List<SearchPlace>> readPois(String regionId) async {
    final file = File('${(await regionDir(regionId)).path}/$poisFile');
    if (!await file.exists()) return [];
    final list = jsonDecode(await file.readAsString()) as List<dynamic>;
    return list
        .map((e) => SearchPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> writeRoutingGraph(
    String regionId,
    Map<String, dynamic> graph,
  ) async {
    final dir = await regionDir(regionId);
    final file = File('${dir.path}/$routingFile');
    await file.writeAsString(jsonEncode(graph));
  }

  Future<Map<String, dynamic>?> readRoutingGraph(String regionId) async {
    final file = File('${(await regionDir(regionId)).path}/$routingFile');
    if (!await file.exists()) return null;
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<void> writeChecksum(String regionId, String checksum) async {
    final dir = await regionDir(regionId);
    await File('${dir.path}/$checksumFile').writeAsString(checksum);
  }

  Future<String?> readChecksum(String regionId) async {
    final file = File('${(await regionDir(regionId)).path}/$checksumFile');
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  Future<int> regionSizeBytes(String regionId) async {
    final dir = await regionDir(regionId);
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> deleteRegion(String regionId) async {
    final dir = await regionDir(regionId);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<List<String>> listInstalledRegionIds() async {
    final rootDir = await root;
    if (!await rootDir.exists()) return [];
    final ids = <String>[];
    await for (final entity in rootDir.list()) {
      if (entity is Directory) {
        final manifest = File('${entity.path}/$manifestFile');
        if (await manifest.exists()) {
          ids.add(entity.path.split(Platform.pathSeparator).last);
        }
      }
    }
    return ids;
  }

  Future<int> totalOfflineBytes() async {
    final ids = await listInstalledRegionIds();
    var total = 0;
    for (final id in ids) {
      total += await regionSizeBytes(id);
    }
    return total;
  }

  Future<bool> verifyIntegrity(String regionId) async {
    final manifest = await readManifest(regionId);
    if (manifest == null) return false;
    final pois = await readPois(regionId);
    final routing = await readRoutingGraph(regionId);
    final checksum = await readChecksum(regionId);
    if (pois.isEmpty || routing == null || checksum == null) return false;
    final computed = _checksumFor(regionId, pois.length, routing.length);
    return computed == checksum.trim();
  }

  String _checksumFor(String regionId, int poiCount, int routingKeys) {
    return '$regionId:$poiCount:$routingKeys'.hashCode.toRadixString(16);
  }

  String computeChecksum(String regionId, int poiCount, int routingKeys) =>
      _checksumFor(regionId, poiCount, routingKeys);
}
