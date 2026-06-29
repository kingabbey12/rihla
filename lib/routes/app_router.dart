import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/core/observability/logging_navigator_observer.dart';
import 'package:rihla/core/router/page_transitions.dart';
import 'package:rihla/features/authentication/presentation/pages/auth_entry_page.dart';
import 'package:rihla/features/launch/presentation/pages/brand_splash_page.dart';
import 'package:rihla/features/launch/presentation/pages/native_splash_page.dart';
import 'package:rihla/features/launch/presentation/pages/onboarding_page.dart';
import 'package:rihla/features/launch/presentation/pages/permission_flow_page.dart';
import 'package:rihla/features/launch/presentation/pages/welcome_page.dart';
import 'package:rihla/features/launch/presentation/providers/launch_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/pages/ai_home_page.dart';
import 'package:rihla/features/emergency/presentation/pages/emergency_launcher_page.dart';
import 'package:rihla/features/emergency/presentation/pages/emergency_dashboard_page.dart';
import 'package:rihla/features/emergency/presentation/pages/report_incident_page.dart';
import 'package:rihla/features/explore/presentation/pages/explore_launcher_page.dart';
import 'package:rihla/features/explore/presentation/pages/explore_nearby_page.dart';
import 'package:rihla/features/driving/presentation/pages/rihla_drive_page.dart';
import 'package:rihla/features/profile/presentation/pages/profile_page.dart';
import 'package:rihla/features/traffic/presentation/pages/traffic_incidents_page.dart';
import 'package:rihla/features/map/presentation/pages/map_page.dart';
import 'package:rihla/features/offline/presentation/pages/offline_center_page.dart';
import 'package:rihla/features/search/presentation/pages/search_page.dart';
import 'package:rihla/features/uae/presentation/pages/uae_settings_page.dart';
import 'package:rihla/features/beta_feedback/domain/entities/beta_feedback_type.dart';
import 'package:rihla/features/beta_feedback/presentation/pages/beta_feedback_page.dart';
import 'package:rihla/features/account/presentation/pages/cloud_settings_page.dart';
import 'package:rihla/routes/route_paths.dart';

/// Provides the application [GoRouter] instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    observers: [LoggingNavigatorObserver()],
    redirect: (context, state) {
      final launchComplete =
          ref.read(appPreferencesRepositoryProvider).launchFlowCompleted;
      if (launchComplete &&
          RoutePaths.launchPaths.contains(state.matchedLocation)) {
        // Returning users skip the launch flow and enter the production
        // map experience (AI Home Dashboard + Maps) directly.
        return RoutePaths.maps;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RoutePaths.splash,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const NativeSplashPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.brandSplash,
        name: RoutePaths.brandSplash,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const BrandSplashPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.welcome,
        name: RoutePaths.welcome,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const WelcomePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RoutePaths.onboarding,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const OnboardingPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.permissions,
        name: RoutePaths.permissions,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const PermissionFlowPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.authentication,
        name: RoutePaths.authentication,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const AuthEntryPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.maps,
        name: RoutePaths.maps,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const MapPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.search,
        name: RoutePaths.search,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const SearchPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.explore,
        name: RoutePaths.explore,
        builder: (context, state) => const ExploreLauncherPage(),
      ),
      GoRoute(
        path: RoutePaths.exploreNearby,
        name: RoutePaths.exploreNearby,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const ExploreNearbyPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.aiHome,
        name: RoutePaths.aiHome,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const AiHomePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.emergency,
        name: RoutePaths.emergency,
        builder: (context, state) => const EmergencyLauncherPage(),
      ),
      GoRoute(
        path: RoutePaths.emergencyDashboard,
        name: RoutePaths.emergencyDashboard,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const EmergencyDashboardPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.reportIncident,
        name: RoutePaths.reportIncident,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const ReportIncidentPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.traffic,
        name: RoutePaths.traffic,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const TrafficIncidentsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.drive,
        name: RoutePaths.drive,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const RihlaDrivePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.profile,
        name: RoutePaths.profile,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const ProfilePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RoutePaths.settings,
        builder: (context, state) => const CloudSettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.uaeSettings,
        name: RoutePaths.uaeSettings,
        builder: (context, state) => const UaeSettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.betaFeedback,
        name: RoutePaths.betaFeedback,
        builder: (context, state) {
          final typeName = state.uri.queryParameters['type'];
          BetaFeedbackType? initialType;
          if (typeName != null) {
            for (final t in BetaFeedbackType.values) {
              if (t.wireName == typeName) {
                initialType = t;
                break;
              }
            }
          }
          return BetaFeedbackPage(initialType: initialType);
        },
      ),
      GoRoute(
        path: RoutePaths.offlineCenter,
        name: RoutePaths.offlineCenter,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const OfflineCenterPage(),
        ),
      ),
    ],
  );

  ref.listen(launchFlowCompletionProvider, (_, _) => router.refresh());

  return router;
});
