import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/presentation/providers/voice_guidance_providers.dart';

/// Announces maneuver instructions without duplicating speech.
class NavigationVoiceCoordinator {
  NavigationVoiceCoordinator(this._ref);

  final Ref _ref;
  String? _lastSpokenInstruction;

  void reset() => _lastSpokenInstruction = null;

  Future<void> announceIfNeeded(NavigationSession session) async {
    if (!session.voiceEnabled) return;
    final instruction = session.currentManeuver.instruction;
    if (instruction == _lastSpokenInstruction) return;
    _lastSpokenInstruction = instruction;
    final voice = _ref.read(voiceGuidanceServiceProvider);
    if (voice.isMuted) {
      await voice.unmute();
    }
    await voice.speak(instruction, languageCode: 'en');
  }

  Future<void> clearQueue() async {
    await _ref.read(voiceGuidanceServiceProvider).clearQueue();
    reset();
  }
}

final navigationVoiceCoordinatorProvider = Provider<NavigationVoiceCoordinator>(
  (ref) => NavigationVoiceCoordinator(ref),
);
