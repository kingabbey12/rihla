import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/routes/feature_route.dart';

/// Placeholder screen for features that have not been implemented yet.
class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({
    super.key,
    required this.feature,
  });

  final FeatureRoute feature;

  String _title(BuildContext context) {
    final l10n = context.l10n;
    return switch (feature) {
      FeatureRoute.authentication => l10n.featureAuthentication,
      FeatureRoute.maps => l10n.featureMaps,
      FeatureRoute.navigation => l10n.featureNavigation,
      FeatureRoute.explore => l10n.featureExplore,
      FeatureRoute.emergency => l10n.featureEmergency,
      FeatureRoute.ai => l10n.featureAi,
      FeatureRoute.profile => l10n.featureProfile,
      FeatureRoute.vehicles => l10n.featureVehicles,
      FeatureRoute.family => l10n.featureFamily,
      FeatureRoute.settings => l10n.featureSettings,
      FeatureRoute.notifications => l10n.featureNotifications,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title(context))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.featurePlaceholderMessage,
            style: context.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
