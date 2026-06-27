import 'package:rihla/features/beta_feedback/data/datasources/beta_feedback_local_datasource.dart';
import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback.dart';
import 'package:rihla/features/beta_feedback/domain/repositories/beta_feedback_repository.dart';

class BetaFeedbackRepositoryImpl implements BetaFeedbackRepository {
  BetaFeedbackRepositoryImpl(this._local);

  final BetaFeedbackLocalDatasource _local;

  @override
  List<BetaFeedback> getAll() => _local.getAll();

  @override
  List<BetaFeedback> getPendingSync() =>
      _local.getAll().where((f) => !f.synced).toList();

  @override
  Future<void> save(BetaFeedback feedback) async {
    final items = _local.getAll();
    final index = items.indexWhere((f) => f.id == feedback.id);
    if (index >= 0) {
      items[index] = feedback;
    } else {
      items.insert(0, feedback);
    }
    await _local.saveAll(items);
  }

  @override
  Future<void> markSynced(String id) async {
    final items = _local.getAll();
    final index = items.indexWhere((f) => f.id == id);
    if (index < 0) return;
    items[index] = items[index].copyWith(synced: true);
    await _local.saveAll(items);
  }

  @override
  Future<void> delete(String id) async {
    final items = _local.getAll()..removeWhere((f) => f.id == id);
    await _local.saveAll(items);
  }
}
