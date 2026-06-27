import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback.dart';
import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback_type.dart';
import 'package:rihla/features/beta_feedback/domain/entities/support_bundle.dart';

abstract class BetaFeedbackService {
  Future<BetaFeedback> submit({
    required BetaFeedbackType type,
    required String message,
    int? rating,
    String? screenshotPath,
    bool includeDiagnostics = false,
    SupportBundle? bundle,
  });

  Future<int> syncPending();
}
