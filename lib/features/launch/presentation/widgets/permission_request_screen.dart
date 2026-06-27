import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rihla/core/constants/app_constants.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/launch/domain/models/permission_request_model.dart';
import 'package:rihla/features/launch/presentation/extensions/permission_request_model_l10n.dart';
import 'package:rihla/shared/widgets/premium_buttons.dart';

/// Reusable permission request screen with allow / not now callbacks.
class PermissionRequestScreen extends StatelessWidget {
  const PermissionRequestScreen({
    super.key,
    required this.model,
    required this.onAllow,
    required this.onNotNow,
  });

  final PermissionRequestModel model;
  final PermissionAllowCallback onAllow;
  final PermissionDeclineCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding * 1.5),
      child: Column(
        children: [
          const Spacer(flex: 2),
          SvgPicture.asset(
            model.iconAsset,
            width: 96,
            height: 96,
          ),
          const SizedBox(height: 40),
          Text(
            model.title(l10n),
            style: context.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            model.explanation(l10n),
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          PremiumPrimaryButton(
            label: l10n.permissionAllow,
            onPressed: () => onAllow(),
          ),
          const SizedBox(height: 12),
          PremiumSecondaryButton(
            label: l10n.permissionNotNow,
            onPressed: () => onNotNow(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
