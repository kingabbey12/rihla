import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';

/// Formats live journey metric values for display.
extension LiveMetricFormatters on BuildContext {
  String formatEta(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return l10n.journeyMinutes(minutes);
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '$hours h $mins min' : '$hours h';
  }

  String formatDistanceKm(double km) => l10n.journeyKm(km.toStringAsFixed(1));

  String formatSpeedKmh(double speed) => l10n.liveJourneySpeedKmh(speed.round());

  String formatFuelLiters(double liters) =>
      l10n.journeyLiters(liters.toStringAsFixed(1));

  String formatBatteryPercent(double percent) =>
      l10n.journeyBatteryPercent(percent.round().toString());

  String formatArrivalTime(DateTime time) {
    final local = TimeOfDay.fromDateTime(time);
    final hour = local.hourOfPeriod == 0 ? 12 : local.hourOfPeriod;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String formatScore(double score) => score.round().toString();
}
