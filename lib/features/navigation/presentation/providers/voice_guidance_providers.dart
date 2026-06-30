import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/data/services/flutter_tts_provider.dart';
import 'package:rihla/features/navigation/data/services/mock_voice_guidance_service.dart';
import 'package:rihla/features/navigation/domain/services/tts_provider.dart';
import 'package:rihla/features/navigation/domain/services/voice_guidance_service.dart';

/// Platform TTS in production. Override with [MockTtsProvider] in tests.
final ttsProviderProvider = Provider<TtsProvider>(
  (ref) => FlutterTtsProvider(),
);

final voiceGuidanceServiceProvider = Provider<VoiceGuidanceService>((ref) {
  return MockVoiceGuidanceService(ref.watch(ttsProviderProvider));
});

final voiceGuidanceMutedProvider = Provider<bool>((ref) {
  return ref.watch(voiceGuidanceServiceProvider).isMuted;
});

final voiceGuidanceQueueProvider = Provider<List<String>>((ref) {
  return ref.watch(voiceGuidanceServiceProvider).queuedInstructions;
});
