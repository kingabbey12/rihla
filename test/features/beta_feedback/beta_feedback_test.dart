import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/remote_config/domain/entities/remote_config.dart';
import 'package:rihla/features/beta_feedback/data/datasources/beta_feedback_local_datasource.dart';
import 'package:rihla/features/beta_feedback/data/repositories/beta_feedback_repository_impl.dart';
import 'package:rihla/features/beta_feedback/data/services/beta_feedback_service_impl.dart';
import 'package:rihla/features/beta_feedback/data/services/beta_metrics_service.dart';
import 'package:rihla/features/beta_feedback/data/services/support_bundle_generator.dart';
import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BetaFeedbackService', () {
    late BetaFeedbackRepositoryImpl repository;
    late BetaFeedbackServiceImpl service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repository = BetaFeedbackRepositoryImpl(
        BetaFeedbackLocalDatasource(prefs),
      );
      service = BetaFeedbackServiceImpl(repository: repository);
    });

    test('submits feedback locally', () async {
      final feedback = await service.submit(
        type: BetaFeedbackType.routingIssue,
        message: 'Wrong turn near Salik gate',
      );
      expect(repository.getAll(), hasLength(1));
      expect(feedback.synced, isFalse);
    });

    test('attaches sanitized diagnostics when consented', () async {
      final bundle = SupportBundleGenerator().generate(
        config: const RemoteConfig(),
        navigationLogs: ['token Bearer abcdef1234567890'],
      );
      final feedback = await service.submit(
        type: BetaFeedbackType.crashReport,
        message: 'App froze',
        includeDiagnostics: true,
        bundle: bundle,
      );
      expect(feedback.diagnostics['app_version'], isNotNull);
      expect(
        feedback.diagnostics.values.join(' '),
        isNot(contains('Bearer')),
      );
    });

    test('sync marks pending items synced', () async {
      await service.submit(
        type: BetaFeedbackType.bugReport,
        message: 'Test',
      );
      final count = await service.syncPending();
      expect(count, 1);
      expect(repository.getPendingSync(), isEmpty);
    });
  });

  group('BetaMetricsService', () {
    test('records daily snapshot counters', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final metrics = BetaMetricsService(prefs);
      await metrics.recordSession();
      await metrics.recordCrashFreeSession();
      final snap = metrics.dailySnapshot();
      expect(snap['dau_sessions'], greaterThanOrEqualTo(1));
      expect(snap['crash_free_session_rate'], isA<double>());
    });
  });
}
