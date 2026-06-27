import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/navigation/data/services/mock_tts_provider.dart';
import 'package:rihla/features/navigation/data/services/mock_voice_guidance_service.dart';

void main() {
  test('voice guidance speaks when unmuted', () async {
    final tts = MockTtsProvider();
    final voice = MockVoiceGuidanceService(tts);

    await voice.speak('Turn right', languageCode: 'en');
    expect(tts.lastSpoken, 'Turn right');
  });

  test('mute prevents speech', () async {
    final tts = MockTtsProvider();
    final voice = MockVoiceGuidanceService(tts);

    await voice.mute();
    await voice.speak('Turn left', languageCode: 'en');
    expect(tts.lastSpoken, isNull);
    expect(voice.isMuted, isTrue);
  });

  test('unmute resumes speech', () async {
    final tts = MockTtsProvider();
    final voice = MockVoiceGuidanceService(tts);

    await voice.mute();
    await voice.unmute();
    await voice.speak('Continue straight', languageCode: 'en');
    expect(tts.lastSpoken, 'Continue straight');
  });
}
