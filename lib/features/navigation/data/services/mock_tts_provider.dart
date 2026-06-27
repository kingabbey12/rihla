import 'package:rihla/features/navigation/domain/services/tts_provider.dart';

/// In-memory mock TTS for development and tests.
class MockTtsProvider implements TtsProvider {
  String? lastSpoken;
  String languageCode = 'en';

  final List<String> history = [];

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    this.languageCode = languageCode;
    lastSpoken = text;
    history.add(text);
  }

  @override
  Future<void> stop() async {
    lastSpoken = null;
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    this.languageCode = languageCode;
  }
}
