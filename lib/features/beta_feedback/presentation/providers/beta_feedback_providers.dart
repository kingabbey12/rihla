import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/observability/analytics_event.dart';
import 'package:rihla/core/observability/analytics_service.dart';
import 'package:rihla/core/observability/crash_reporter.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/core/remote_config/presentation/providers/remote_config_providers.dart';
import 'package:rihla/features/beta_feedback/data/datasources/beta_feedback_local_datasource.dart';
import 'package:rihla/features/beta_feedback/data/repositories/beta_feedback_repository_impl.dart';
import 'package:rihla/features/beta_feedback/data/services/beta_feedback_service_impl.dart';
import 'package:rihla/features/beta_feedback/data/services/beta_metrics_service.dart';
import 'package:rihla/features/beta_feedback/data/services/support_bundle_generator.dart';
import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback_type.dart';
import 'package:rihla/features/beta_feedback/domain/entities/support_bundle.dart';
import 'package:rihla/features/beta_feedback/domain/models/beta_feedback_state.dart';
import 'package:rihla/features/beta_feedback/domain/repositories/beta_feedback_repository.dart';
import 'package:rihla/features/beta_feedback/domain/services/beta_feedback_service.dart';

final betaFeedbackLocalDatasourceProvider =
    Provider<BetaFeedbackLocalDatasource>(
  (ref) => BetaFeedbackLocalDatasource(ref.watch(sharedPreferencesProvider)),
);

final betaFeedbackRepositoryProvider = Provider<BetaFeedbackRepository>(
  (ref) => BetaFeedbackRepositoryImpl(
    ref.watch(betaFeedbackLocalDatasourceProvider),
  ),
);

final betaMetricsServiceProvider = Provider<BetaMetricsService>(
  (ref) => BetaMetricsService(ref.watch(sharedPreferencesProvider)),
);

final betaFeedbackServiceProvider = Provider<BetaFeedbackService>(
  (ref) => BetaFeedbackServiceImpl(
    repository: ref.watch(betaFeedbackRepositoryProvider),
    analytics: ref.watch(analyticsServiceProvider),
  ),
);

final supportBundleGeneratorProvider = Provider<SupportBundleGenerator>(
  (ref) => SupportBundleGenerator(
    crashReporter: ref.watch(crashReporterProvider),
  ),
);

final betaFeedbackControllerProvider =
    NotifierProvider<BetaFeedbackController, BetaFeedbackState>(
  BetaFeedbackController.new,
);

class BetaFeedbackController extends Notifier<BetaFeedbackState> {
  @override
  BetaFeedbackState build() => BetaFeedbackIdle();

  Future<void> submit({
    required BetaFeedbackType type,
    required String message,
    int? rating,
    String? screenshotPath,
    bool includeDiagnostics = false,
  }) async {
    state = BetaFeedbackSubmitting();
    try {
      SupportBundle? bundle;
      if (includeDiagnostics) {
        bundle = ref.read(supportBundleGeneratorProvider).generate(
              config: ref.read(remoteConfigProvider),
            );
      }
      final feedback = await ref.read(betaFeedbackServiceProvider).submit(
            type: type,
            message: message,
            rating: rating,
            screenshotPath: screenshotPath,
            includeDiagnostics: includeDiagnostics,
            bundle: bundle,
          );
      state = BetaFeedbackSubmitted(feedback);
    } catch (e) {
      state = BetaFeedbackError(e.toString());
    }
  }

  void reset() => state = BetaFeedbackIdle();
}

final betaMetricsSnapshotProvider = Provider<Map<String, dynamic>>(
  (ref) => ref.watch(betaMetricsServiceProvider).dailySnapshot(),
);
