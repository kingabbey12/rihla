import 'package:rihla/core/observability/analytics_event.dart';
import 'package:rihla/core/observability/analytics_service.dart';
import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback.dart';
import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback_type.dart';
import 'package:rihla/features/beta_feedback/domain/entities/support_bundle.dart';
import 'package:rihla/features/beta_feedback/domain/repositories/beta_feedback_repository.dart';
import 'package:rihla/features/beta_feedback/domain/services/beta_feedback_service.dart';

class BetaFeedbackServiceImpl implements BetaFeedbackService {
  BetaFeedbackServiceImpl({
    required BetaFeedbackRepository repository,
    AnalyticsService? analytics,
  })  : _repository = repository,
        _analytics = analytics;

  final BetaFeedbackRepository _repository;
  final AnalyticsService? _analytics;

  @override
  Future<BetaFeedback> submit({
    required BetaFeedbackType type,
    required String message,
    int? rating,
    String? screenshotPath,
    bool includeDiagnostics = false,
    SupportBundle? bundle,
  }) async {
    final feedback = BetaFeedback(
      id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      message: message.trim(),
      rating: rating,
      screenshotPath: screenshotPath,
      includeDiagnostics: includeDiagnostics,
      diagnostics: includeDiagnostics && bundle != null
          ? bundle.toFlatMap()
          : const {},
      createdAt: DateTime.now(),
    );
    await _repository.save(feedback);
    _analytics?.logEvent(
      AnalyticsEvent.appOpened,
      properties: {
        'beta_feedback': type.wireName,
        'has_diagnostics': '$includeDiagnostics',
      },
    );
    return feedback;
  }

  @override
  Future<int> syncPending() async {
    final pending = _repository.getPendingSync();
    for (final item in pending) {
      await _repository.markSynced(item.id);
    }
    return pending.length;
  }
}
