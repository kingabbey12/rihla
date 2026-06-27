import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/core/router/page_transitions.dart';
import 'package:rihla/features/authentication/presentation/pages/auth_entry_page.dart';
import 'package:rihla/features/launch/presentation/pages/brand_splash_page.dart';
import 'package:rihla/features/launch/presentation/pages/native_splash_page.dart';
import 'package:rihla/features/launch/presentation/pages/onboarding_page.dart';
import 'package:rihla/features/launch/presentation/pages/permission_flow_page.dart';
import 'package:rihla/features/launch/presentation/pages/welcome_page.dart';
import 'package:rihla/features/launch/presentation/providers/launch_providers.dart';
import 'package:rihla/features/location/presentation/pages/location_debug_page.dart';
import 'package:rihla/features/map/presentation/pages/map_page.dart';
import 'package:rihla/features/navigation/presentation/pages/navigation_session_debug_page.dart';
import 'package:rihla/features/routing/presentation/pages/route_debug_page.dart';
import 'package:rihla/features/search/presentation/pages/search_page.dart';
import 'package:rihla/routes/feature_route.dart';
import 'package:rihla/routes/pages/feature_placeholder_page.dart';
import 'package:rihla/routes/pages/home_page.dart';
import 'package:rihla/routes/route_paths.dart';

/// Provides the application [GoRouter] instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final launchComplete =
          ref.read(appPreferencesRepositoryProvider).launchFlowCompleted;
      if (launchComplete &&
          RoutePaths.launchPaths.contains(state.matchedLocation)) {
        return RoutePaths.home;
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
        path: RoutePaths.home,
        name: RoutePaths.home,
        pageBuilder: (context, state) => fadeSlidePage(
          key: state.pageKey,
          child: const HomePage(),
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
        path: RoutePaths.navigation,
        name: RoutePaths.navigation,
        builder: (context, state) => const FeaturePlaceholderPage(
          feature: FeatureRoute.navigation,
        ),
      ),
      GoRoute(
        path: RoutePaths.explore,
        name: RoutePaths.explore,
        builder: (context, state) => const FeaturePlaceholderPage(
          feature: FeatureRoute.explore,
        ),
      ),
      GoRoute(
        path: RoutePaths.emergency,
        name: RoutePaths.emergency,
        builder: (context, state) => const FeaturePlaceholderPage(
          feature: FeatureRoute.emergency,
        ),
      ),
      GoRoute(
        path: RoutePaths.ai,
        name: RoutePaths.ai,
        builder: (context, state) => const FeaturePlaceholderPage(
          feature: FeatureRoute.ai,
        ),
      ),
      GoRoute(
        path: RoutePaths.profile,
        name: RoutePaths.profile,
        builder: (context, state) => const FeaturePlaceholderPage(
          feature: FeatureRoute.profile,
        ),
      ),
      GoRoute(
        path: RoutePaths.vehicles,
        name: RoutePaths.vehicles,
        builder: (context, state) => const FeaturePlaceholderPage(
          feature: FeatureRoute.vehicles,
        ),
      ),
      GoRoute(
        path: RoutePaths.family,
        name: RoutePaths.family,
        builder: (context, state) => const FeaturePlaceholderPage(
          feature: FeatureRoute.family,
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RoutePaths.settings,
        builder: (context, state) => const FeaturePlaceholderPage(
          feature: FeatureRoute.settings,
        ),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        name: RoutePaths.notifications,
        builder: (context, state) => const FeaturePlaceholderPage(
          feature: FeatureRoute.notifications,
        ),
      ),
      GoRoute(
        path: RoutePaths.locationDebug,
        name: RoutePaths.locationDebug,
        builder: (context, state) => const LocationDebugPage(),
      ),
      GoRoute(
        path: RoutePaths.routeDebug,
        name: RoutePaths.routeDebug,
        builder: (context, state) => const RouteDebugPage(),
      ),
      GoRoute(
        path: RoutePaths.navigationSessionDebug,
        name: RoutePaths.navigationSessionDebug,
        builder: (context, state) => const NavigationSessionDebugPage(),
      ),
    ],
  );

  ref.listen(launchFlowCompletionProvider, (_, _) => router.refresh());

  return router;
});
