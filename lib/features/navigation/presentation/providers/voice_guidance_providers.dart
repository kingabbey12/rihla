import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/navigation/data/services/mock_tts_provider.dart';
import 'package:rihla/features/navigation/data/services/mock_voice_guidance_service.dart';
import 'package:rihla/features/navigation/domain/services/tts_provider.dart';
import 'package:rihla/features/navigation/domain/services/voice_guidance_service.dart';

final ttsProviderProvider = Provider<TtsProvider>(
  (ref) => MockTtsProvider(),
);

final voiceGuidanceServiceProvider = Provider<VoiceGuidanceService>((ref) {
  return MockVoiceGuidanceService(ref.watch(ttsProviderProvider) as MockTtsProvider);
});

final voiceGuidanceMutedProvider = Provider<bool>((ref) {
  return ref.watch(voiceGuidanceServiceProvider).isMuted;
});

final voiceGuidanceQueueProvider = Provider<List<String>>((ref) {
  return ref.watch(voiceGuidanceServiceProvider).queuedInstructions;
});
