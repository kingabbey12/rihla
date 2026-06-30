import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/presentation/providers/voice_guidance_providers.dart';
import 'package:rihla/localization/locale_provider.dart';

/// Announces maneuver instructions with distance-tiered prompts and no repeats.
class NavigationVoiceCoordinator {
  NavigationVoiceCoordinator(this._ref);

  final Ref _ref;
  String? _lastSpokenKey;

  void reset() => _lastSpokenKey = null;

  Future<void> announceIfNeeded(NavigationSession session) async {
    if (!session.voiceEnabled) return;

    final voice = _ref.read(voiceGuidanceServiceProvider);
    if (voice.isMuted) return;

    final maneuver = session.currentManeuver;
    final instruction = maneuver.instruction.trim();
    if (instruction.isEmpty) return;

    final distanceM = (maneuver.distanceToManeuverKm * 1000).round();
    final tier = tierForDistance(distanceM);
    final key = '$tier|$instruction';
    if (key == _lastSpokenKey) return;
    _lastSpokenKey = key;

    final languageCode =
        _ref.exists(localeProvider) ? _ref.read(localeProvider).languageCode : 'en';
    final prompt = buildPrompt(
      distanceMeters: distanceM,
      instruction: instruction,
      languageCode: languageCode,
    );

    await voice.speak(prompt, languageCode: languageCode);
  }

  Future<void> clearQueue() async {
    await _ref.read(voiceGuidanceServiceProvider).clearQueue();
    reset();
  }

  static String tierForDistance(int meters) {
    if (meters > 800) return 'far';
    if (meters > 300) return 'mid';
    if (meters > 80) return 'near';
    return 'now';
  }

  static String buildPrompt({
    required int distanceMeters,
    required String instruction,
    required String languageCode,
  }) {
    if (languageCode == 'ar') {
      if (distanceMeters > 800) {
        final km = (distanceMeters / 1000).toStringAsFixed(1);
        return 'بعد $km كم، $instruction';
      }
      if (distanceMeters > 80) {
        return 'بعد $distanceMeters متر، $instruction';
      }
      return instruction;
    }

    if (distanceMeters > 800) {
      final km = (distanceMeters / 1000).toStringAsFixed(1);
      return 'In $km kilometers, $instruction';
    }
    if (distanceMeters > 80) {
      return 'In $distanceMeters meters, $instruction';
    }
    return instruction;
  }
}

final navigationVoiceCoordinatorProvider = Provider<NavigationVoiceCoordinator>(
  (ref) => NavigationVoiceCoordinator(ref),
);
