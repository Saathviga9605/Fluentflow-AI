import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
    required LocalStorageService storageService,
  })  : _authService = authService,
        _storageService = storageService;

  final AuthService _authService;
  final LocalStorageService _storageService;

  UserProfile? _user;
  bool _isInitializing = true;
  bool _isBusy = false;
  bool _onboardingSeen = false;
  String? _error;

  UserProfile? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isInitializing => _isInitializing;
  bool get isBusy => _isBusy;
  bool get onboardingSeen => _onboardingSeen;
  String? get error => _error;

  List<Map<dynamic, dynamic>> get fluencySnapshots {
    final userId = _user?.userId;
    if (userId == null) return <Map<dynamic, dynamic>>[];
    return _storageService.getFluencySnapshots(userId);
  }

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    await _storageService.initialize();
    _onboardingSeen = _storageService.onboardingSeen;

    if (_storageService.forceLoggedOut) {
      _user = _storageService.activeUser;
    } else {
      _user = _authService.currentUserProfile() ?? _storageService.activeUser;
    }

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> markOnboardingSeen() async {
    _onboardingSeen = true;
    await _storageService.setOnboardingSeen(true);
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithGoogle();
      await _storageService.setForceLoggedOut(false);
      await _storageService.saveActiveUser(_user!);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmailFallback({
    required String name,
    required String email,
  }) async {
    _user = UserProfile(
      userId: 'local-${DateTime.now().millisecondsSinceEpoch}',
      name: name.isEmpty ? 'FluentFlow Learner' : name,
      email: email,
    );
    await _storageService.setForceLoggedOut(false);
    await _storageService.saveActiveUser(_user!);
    notifyListeners();
  }

  Future<void> refreshUserStats() async {
    if (_user == null) return;
    final snapshots = _storageService.getFluencySnapshots(_user!.userId);
    if (snapshots.isEmpty) return;

    final average = snapshots
            .map((item) => (item['score'] as num?)?.toDouble() ?? 0)
            .reduce((a, b) => a + b) /
        snapshots.length;

    _user = _user!.copyWith(
      averageFluencyScore: average,
      totalSessions: snapshots.length,
    );
    await _storageService.saveActiveUser(_user!);
    notifyListeners();
  }

  Future<void> updateAvatarEmoji(String emoji) async {
    if (_user == null) return;
    _user = _user!.copyWith(avatarEmoji: emoji);
    await _storageService.saveActiveUser(_user!);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
    } catch (_) {
      // Continue local logout even if remote sign-out fails.
    } finally {
      await _storageService.setForceLoggedOut(true);
      await _storageService.clearActiveUser();
      _user = null;
      notifyListeners();
    }
  }
}
