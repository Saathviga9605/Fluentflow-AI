import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  String _lastVoiceProfile = 'Female';
  String _lastLanguage = 'en-US';
  double _lastSpeechRate = 1.0;

  Future<void> initialize({
    required String voiceProfile,
    required String language,
    required double speechRate,
  }) async {
    if (_initialized &&
        _lastVoiceProfile == voiceProfile &&
        _lastLanguage == language &&
        _lastSpeechRate == speechRate) {
      return;
    }

    await _tts.setLanguage(language);
    await _tts.setSpeechRate(speechRate.clamp(0.35, 1.0));
    await _tts.setPitch(1.0);

    final voices = await _tts.getVoices;
    if (voices is List) {
      final keywords = voiceProfile == 'Male'
          ? ['male', 'man', 'david', 'alex', 'daniel']
          : ['female', 'woman', 'samantha', 'karen', 'aria'];

      Map<dynamic, dynamic>? selected;
      for (final item in voices) {
        if (item is! Map) continue;
        final map = Map<dynamic, dynamic>.from(item);
        final name = (map['name'] ?? '').toString().toLowerCase();
        if (keywords.any((k) => name.contains(k))) {
          selected = map;
          break;
        }
      }

      if (selected != null) {
        await _tts.setVoice({
          'name': selected['name'],
          'locale': selected['locale'],
        });
      }
    }

    _initialized = true;
    _lastVoiceProfile = voiceProfile;
    _lastLanguage = language;
    _lastSpeechRate = speechRate;
  }

  Future<void> speak(
    String text, {
    required String voiceProfile,
    required String language,
    required double speechRate,
  }) async {
    if (text.trim().isEmpty) return;
    await initialize(
      voiceProfile: voiceProfile,
      language: language,
      speechRate: speechRate,
    );
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
