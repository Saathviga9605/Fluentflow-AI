import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat_message.dart';
import '../models/user_profile.dart';

class LocalStorageService {
  static const String _appBoxName = 'fluentflow_app';
  static const String _sessionBoxName = 'fluentflow_sessions';
  static const String _onboardingKey = 'onboarding_seen';
  static const String _activeUserKey = 'active_user';
  static const String _settingsKey = 'app_settings';
  static const String _forceLoggedOutKey = 'force_logged_out';

  late final Box _appBox;
  late final Box _sessionBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _appBox = await Hive.openBox(_appBoxName);
    _sessionBox = await Hive.openBox(_sessionBoxName);
  }

  bool get onboardingSeen => _appBox.get(_onboardingKey, defaultValue: false) as bool;

  Future<void> setOnboardingSeen(bool seen) async {
    await _appBox.put(_onboardingKey, seen);
  }

  UserProfile? get activeUser {
    final data = _appBox.get(_activeUserKey);
    if (data is Map) {
      return UserProfile.fromJson(data);
    }
    return null;
  }

  Future<void> saveActiveUser(UserProfile user) async {
    await _appBox.put(_activeUserKey, user.toJson());
  }

  Future<void> clearActiveUser() async {
    await _appBox.delete(_activeUserKey);
  }

  Map<String, dynamic> get appSettings {
    final data = _appBox.get(_settingsKey, defaultValue: <String, dynamic>{});
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    await _appBox.put(_settingsKey, settings);
  }

  bool get forceLoggedOut =>
      _appBox.get(_forceLoggedOutKey, defaultValue: false) as bool;

  Future<void> setForceLoggedOut(bool value) async {
    await _appBox.put(_forceLoggedOutKey, value);
  }

  Future<void> saveSessionHistory(String userId, List<ChatMessage> messages) async {
    final entries = messages
        .map((m) => {
              'id': m.id,
              'role': m.role.name,
              'text': m.text,
              'timestamp': m.timestamp?.toIso8601String(),
            })
        .toList();

    await _sessionBox.put('history_$userId', entries);
  }

  List<Map<dynamic, dynamic>> getSessionHistory(String userId) {
    final items = _sessionBox.get('history_$userId', defaultValue: <Map<dynamic, dynamic>>[]);
    if (items is List) {
      return items.cast<Map<dynamic, dynamic>>();
    }
    return [];
  }

  Future<void> saveFluencySnapshot({
    required String userId,
    required double score,
    required int fillerCount,
  }) async {
    final key = 'stats_$userId';
    final existing = (_sessionBox.get(key, defaultValue: <Map<dynamic, dynamic>>[]) as List)
        .cast<Map<dynamic, dynamic>>();
    existing.add({
      'score': score,
      'fillerCount': fillerCount,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _sessionBox.put(key, existing);
  }

  List<Map<dynamic, dynamic>> getFluencySnapshots(String userId) {
    final items = _sessionBox.get('stats_$userId', defaultValue: <Map<dynamic, dynamic>>[]);
    if (items is List) {
      return items.cast<Map<dynamic, dynamic>>();
    }
    return [];
  }
}
