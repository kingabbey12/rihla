import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rihla/app.dart';
import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/crash_reporter.dart';
import 'package:rihla/core/error/app_error_widget.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/core/performance/performance_config.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/core/observability/product_analytics.dart';
import 'package:rihla/features/beta_feedback/data/services/beta_metrics_service_recorder.dart';
import 'package:rihla/features/beta_feedback/presentation/providers/beta_feedback_providers.dart';
import 'package:rihla/features/beta_feedback/presentation/coordinators/beta_feedback_coordinator.dart';
import 'package:rihla/core/remote_config/presentation/providers/remote_config_providers.dart';
import 'package:rihla/features/account/presentation/providers/account_providers.dart';
import 'package:rihla/features/offline/presentation/widgets/offline_bootstrap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Single crash-reporting instance shared by global error hooks and DI.
  // Production swaps this for a Firebase Crashlytics adapter (see
  // docs/PHASE18_PRODUCTION_HARDENING.md); default builds stay no-op.
  final CrashReporter crashReporter = ApiConfig.crashReportingEnabled
      ? BufferingCrashReporter()
      : const NoOpCrashReporter();

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    PerformanceConfig.apply();

    // Never let a widget build failure paint a bare white/red screen — render a
    // readable error surface instead (shows details in debug). This is the
    // safety net for the navigation transition and every other screen.
    ErrorWidget.builder = buildAppErrorWidget;

    // Route framework + platform errors into the crash reporter.
    final priorOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      crashReporter.recordNonFatal(
        details.exception,
        details.stack,
        reason: details.context?.toDescription(),
      );
      priorOnError?.call(details);
    };
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      crashReporter.recordFatal(error, stack, reason: 'platformDispatcher');
      return true;
    };

    crashReporter.addBreadcrumb(
      Breadcrumb(message: 'app_bootstrap', category: ObservabilityCategory.app),
    );

    final prefs = await SharedPreferences.getInstance();

    if (ApiConfig.cloudEnabled) {
      await Supabase.initialize(
        url: ApiConfig.supabaseUrl!,
        anonKey: ApiConfig.supabaseAnonKey!,
      );
    }

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          crashReporterProvider.overrideWithValue(crashReporter),
          productMetricsRecorderProvider.overrideWith(
            (ref) => BetaMetricsServiceRecorder(
              ref.watch(betaMetricsServiceProvider),
            ),
          ),
        ],
        child: const _AccountBootstrap(
          child: BetaFeedbackBootstrap(
            child: OfflineBootstrap(child: App()),
          ),
        ),
      ),
    );
  }, (error, stack) {
    crashReporter.recordFatal(error, stack, reason: 'uncaught_zone_error');
  });
}

class _AccountBootstrap extends ConsumerStatefulWidget {
  const _AccountBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_AccountBootstrap> createState() => _AccountBootstrapState();
}

class _AccountBootstrapState extends ConsumerState<_AccountBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountControllerProvider.notifier).initialize();
      ref.read(remoteConfigControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
