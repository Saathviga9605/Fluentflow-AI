import 'package:flutter/foundation.dart';

import '../services/local_storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({required LocalStorageService storageService})
      : _storageService = storageService;

  final LocalStorageService _storageService;

  String _language = 'Tamil + English';
  double _speechSpeed = 1.0;
  double _difficulty = 0.4;
  bool _safeMode = true;
  String _voiceProfile = 'Female';
  bool _autoSpeakReplies = true;

  Future<void> initialize() async {
    final saved = _storageService.appSettings;
    _language = (saved['language'] as String?) ?? _language;
    _speechSpeed = (saved['speechSpeed'] as num?)?.toDouble() ?? _speechSpeed;
    _difficulty = (saved['difficulty'] as num?)?.toDouble() ?? _difficulty;
    _safeMode = (saved['safeMode'] as bool?) ?? _safeMode;
    _voiceProfile = (saved['voiceProfile'] as String?) ?? _voiceProfile;
    _autoSpeakReplies = (saved['autoSpeakReplies'] as bool?) ?? _autoSpeakReplies;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storageService.saveAppSettings({
      'language': _language,
      'speechSpeed': _speechSpeed,
      'difficulty': _difficulty,
      'safeMode': _safeMode,
      'voiceProfile': _voiceProfile,
      'autoSpeakReplies': _autoSpeakReplies,
    });
  }

  String get language => _language;
  double get speechSpeed => _speechSpeed;
  double get difficulty => _difficulty;
  bool get safeMode => _safeMode;
  String get voiceProfile => _voiceProfile;
  bool get autoSpeakReplies => _autoSpeakReplies;

  void updateLanguage(String value) {
    _language = value;
    _persist();
    notifyListeners();
  }

  void updateSpeechSpeed(double value) {
    _speechSpeed = value;
    _persist();
    notifyListeners();
  }

  void updateDifficulty(double value) {
    _difficulty = value;
    _persist();
    notifyListeners();
  }

  void updateSafeMode(bool value) {
    _safeMode = value;
    _persist();
    notifyListeners();
  }

  void updateVoiceProfile(String value) {
    _voiceProfile = value;
    _persist();
    notifyListeners();
  }

  void updateAutoSpeakReplies(bool value) {
    _autoSpeakReplies = value;
    _persist();
    notifyListeners();
  }

  String difficultyLabel(double value) {
    if (value < 0.25) return 'Very gentle';
    if (value < 0.5) return 'Gentle';
    if (value < 0.75) return 'Balanced';
    return 'Challenging';
  }
}
