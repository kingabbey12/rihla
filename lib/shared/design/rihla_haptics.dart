import 'package:flutter/services.dart';

/// One semantic haptic language for the whole app. Call these by intent rather
/// than reaching for [HapticFeedback] directly, so the same gesture feels the
/// same everywhere.
abstract final class RihlaHaptics {
  /// Light tick for selecting items, chips, list rows.
  static void selection() => HapticFeedback.selectionClick();

  /// Moving between screens / tabs / steps.
  static void navigation() => HapticFeedback.lightImpact();

  /// Confirming a choice (route selection, applying a filter).
  static void confirmation() => HapticFeedback.mediumImpact();

  /// A cautionary moment the user should notice.
  static void warning() => HapticFeedback.mediumImpact();

  /// Something failed.
  static void error() => HapticFeedback.heavyImpact();

  /// A positive completion (saved, sent, arrived).
  static void success() => HapticFeedback.lightImpact();

  /// Emergency escalation — strongest feedback.
  static void sos() => HapticFeedback.heavyImpact();

  /// AI responded / suggestion surfaced.
  static void ai() => HapticFeedback.selectionClick();

  /// Choosing a route option.
  static void routeSelection() => HapticFeedback.mediumImpact();

  /// Starting a journey.
  static void journeyStart() => HapticFeedback.mediumImpact();

  /// Arriving at the destination.
  static void arrival() => HapticFeedback.lightImpact();
}
