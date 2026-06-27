/// Spoken turn-by-turn guidance with queueing and mute support.
abstract class VoiceGuidanceService {
  bool get isMuted;

  Future<void> speak(String instruction, {required String languageCode});

  Future<void> mute();

  Future<void> unmute();

  Future<void> clearQueue();

  List<String> get queuedInstructions;
}
