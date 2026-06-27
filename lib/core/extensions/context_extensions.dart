import 'package:flutter/material.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

extension BuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;

  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}
