import 'package:flutter_tts/flutter_tts.dart';
import 'package:rihla/features/navigation/domain/services/tts_provider.dart';

/// Production text-to-speech using the platform engine via [FlutterTts].
class FlutterTtsProvider implements TtsProvider {
  FlutterTtsProvider() : _tts = FlutterTts() {
    _tts.awaitSpeakCompletion(true);
  }

  final FlutterTts _tts;
  String _languageCode = 'en';
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1);
    await _tts.setPitch(1);
    await setLanguage(_languageCode);
    _initialized = true;
  }

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    if (text.trim().isEmpty) return;
    await _ensureInitialized();
    if (languageCode != _languageCode) {
      await setLanguage(languageCode);
    }
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;
    final locale = languageCode == 'ar' ? 'ar-AE' : 'en-US';
    await _tts.setLanguage(locale);
  }
}
