import 'package:flutter/material.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

extension RouteProfileL10n on BuildContext {
  String labelForRouteProfile(RouteProfile profile) {
    final l10n = AppLocalizations.of(this);
    return switch (profile) {
      RouteProfile.safe => l10n.routeProfileSafe,
      RouteProfile.fast => l10n.routeProfileFast,
      RouteProfile.eco => l10n.routeProfileEco,
      RouteProfile.scenic => l10n.routeProfileScenic,
    };
  }

  IconData iconForRouteProfile(RouteProfile profile) => switch (profile) {
        RouteProfile.safe => Icons.shield_outlined,
        RouteProfile.fast => Icons.speed_outlined,
        RouteProfile.eco => Icons.eco_outlined,
        RouteProfile.scenic => Icons.landscape_outlined,
      };
}
