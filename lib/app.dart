import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/config/app_config.dart';
import 'package:rihla/core/accessibility/a11y.dart';
import 'package:rihla/features/offline/presentation/widgets/offline_bootstrap.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/localization/locale_provider.dart';
import 'package:rihla/routes/app_router.dart';
import 'package:rihla/theme/app_theme.dart';
import 'package:rihla/theme/theme_provider.dart';

/// Root application widget.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final highContrast = ref.watch(highContrastProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: highContrast ? AppTheme.highContrastLight : AppTheme.light,
      darkTheme: highContrast ? AppTheme.highContrastDark : AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        // Clamp text scaling so accessibility font sizes never break layouts.
        // The offline banner lives here (below MaterialApp) so it has access to
        // Directionality, MediaQuery, Theme, and Localizations.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: A11y.clampedTextScaler(context),
          ),
          child: OfflineBannerOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
