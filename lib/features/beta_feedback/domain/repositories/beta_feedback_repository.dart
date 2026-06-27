import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback.dart';

abstract class BetaFeedbackRepository {
  List<BetaFeedback> getAll();
  List<BetaFeedback> getPendingSync();
  Future<void> save(BetaFeedback feedback);
  Future<void> markSynced(String id);
  Future<void> delete(String id);
}
