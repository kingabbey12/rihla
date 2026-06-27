import 'package:rihla/features/launch/domain/models/permission_request_model.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

/// Resolves localized strings for [PermissionRequestModel].
extension PermissionRequestModelL10n on PermissionRequestModel {
  String title(AppLocalizations l10n) => switch (id) {
        'location' => l10n.permissionLocationTitle,
        'notifications' => l10n.permissionNotificationsTitle,
        'camera' => l10n.permissionCameraTitle,
        'microphone' => l10n.permissionMicrophoneTitle,
        'background_location' => l10n.permissionBackgroundLocationTitle,
        _ => id,
      };

  String explanation(AppLocalizations l10n) => switch (id) {
        'location' => l10n.permissionLocationExplanation,
        'notifications' => l10n.permissionNotificationsExplanation,
        'camera' => l10n.permissionCameraExplanation,
        'microphone' => l10n.permissionMicrophoneExplanation,
        'background_location' => l10n.permissionBackgroundLocationExplanation,
        _ => '',
      };
}
