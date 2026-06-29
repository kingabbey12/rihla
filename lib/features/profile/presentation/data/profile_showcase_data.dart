import 'package:flutter/material.dart';

/// Model types for the profile dashboard. Stats, history, and achievements
/// are populated from live backends when available; empty states are shown
/// until real trip telemetry is integrated.
class ProfileStat {
  const ProfileStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    this.prefix = '',
    this.suffix = '',
  });

  final IconData icon;
  final String label;
  final int value;
  final List<Color> gradient;
  final String prefix;
  final String suffix;
}

class JourneyHistoryEntry {
  const JourneyHistoryEntry({
    required this.destination,
    required this.dateLabel,
    required this.distanceKm,
    required this.durationMinutes,
    required this.score,
    required this.gradient,
  });

  final String destination;
  final String dateLabel;
  final double distanceKm;
  final int durationMinutes;
  final int score;
  final List<Color> gradient;
}

class ProfileAchievement {
  const ProfileAchievement({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.unlocked,
    this.progress = 1.0,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final bool unlocked;
  final double progress;
}
