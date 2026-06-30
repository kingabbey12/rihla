import 'package:rihla/features/navigation/domain/services/tts_provider.dart';
import 'package:rihla/features/navigation/domain/services/voice_guidance_service.dart';

/// FIFO voice instruction queue with mute support.
class VoiceQueue {
  VoiceQueue();

  final List<String> _pending = [];
  bool _isProcessing = false;

  List<String> get pending => List.unmodifiable(_pending);

  Future<void> enqueue(
    String instruction, {
    required TtsProvider tts,
    required String languageCode,
    required bool muted,
  }) async {
    _pending.add(instruction);
    if (_isProcessing) return;
    _isProcessing = true;
    while (_pending.isNotEmpty) {
      final next = _pending.removeAt(0);
      if (!muted) {
        await tts.speak(next, languageCode: languageCode);
      }
    }
    _isProcessing = false;
  }

  void clear() => _pending.clear();
}

/// FIFO voice guidance backed by any [TtsProvider] (mock or platform).
class MockVoiceGuidanceService implements VoiceGuidanceService {
  MockVoiceGuidanceService(this._tts);

  final TtsProvider _tts;
  final VoiceQueue _queue = VoiceQueue();
  bool _muted = false;
  String _languageCode = 'en';

  @override
  bool get isMuted => _muted;

  @override
  List<String> get queuedInstructions => _queue.pending;

  @override
  Future<void> speak(String instruction, {required String languageCode}) async {
    _languageCode = languageCode;
    await _queue.enqueue(
      instruction,
      tts: _tts,
      languageCode: languageCode,
      muted: _muted,
    );
  }

  @override
  Future<void> mute() async {
    _muted = true;
    await _tts.stop();
  }

  @override
  Future<void> unmute() async {
    _muted = false;
  }

  @override
  Future<void> clearQueue() async {
    _queue.clear();
    await _tts.stop();
  }

  void setLanguage(String languageCode) {
    _languageCode = languageCode;
    _tts.setLanguage(languageCode);
  }

  String get languageCode => _languageCode;
}
