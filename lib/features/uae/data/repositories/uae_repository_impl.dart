import 'package:rihla/features/uae/data/datasources/uae_local_datasource.dart';
import 'package:rihla/features/uae/domain/entities/uae_intelligence_snapshot.dart';
import 'package:rihla/features/uae/domain/entities/uae_preferences.dart';
import 'package:rihla/features/uae/domain/repositories/uae_repository.dart';

class UaeRepositoryImpl implements UaeRepository {
  UaeRepositoryImpl(this._local);

  final UaeLocalDatasource _local;
  UaeIntelligenceSnapshot? _lastSnapshot;

  @override
  UaePreferences getPreferences() => _local.getPreferences();

  @override
  Future<UaePreferences> savePreferences(UaePreferences preferences) async {
    await _local.savePreferences(preferences);
    return preferences;
  }

  @override
  UaeIntelligenceSnapshot? getLastSnapshot() => _lastSnapshot;

  @override
  Future<void> saveSnapshot(UaeIntelligenceSnapshot snapshot) async {
    _lastSnapshot = snapshot;
    await _local.saveSnapshotRegion(snapshot.region.name);
  }
}
