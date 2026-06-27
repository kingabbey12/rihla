/// Future text-to-speech provider contract.
abstract class TtsProvider {
  Future<void> speak(String text, {required String languageCode});

  Future<void> stop();

  Future<void> setLanguage(String languageCode);
}
