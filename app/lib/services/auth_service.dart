import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_profile.dart';

class AuthService {
  FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  String? _lastFirebaseError;

  FirebaseAuth? get _firebaseAuth {
    try {
      _auth ??= FirebaseAuth.instance;
      _lastFirebaseError = null;
      return _auth;
    } catch (e) {
      _lastFirebaseError = e.toString();
      return null;
    }
  }

  Future<void> initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
    } catch (_) {
      // Ignore initialization failures in local/dev until Firebase is configured.
    }
  }

  UserProfile? currentUserProfile() {
    final user = _firebaseAuth?.currentUser;
    if (user == null) return null;
    return UserProfile(
      userId: user.uid,
      name: user.displayName ?? 'FluentFlow Learner',
      email: user.email ?? 'unknown@email.com',
      photoUrl: user.photoURL,
    );
  }

  Future<UserProfile> signInWithGoogle() async {
    final authClient = _firebaseAuth;
    if (authClient == null) {
      final details = _lastFirebaseError == null ? '' : ' ($_lastFirebaseError)';
      throw Exception(
        'Firebase is not initialized. Complete Firebase platform setup and run on a configured platform$details',
      );
    }

    await initializeGoogleSignIn();

    GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } catch (e) {
      throw Exception('Google Sign-In failed. Ensure Firebase and OAuth client are configured.');
    }

    final auth = account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
    );

    final userCredential = await authClient.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw Exception('Unable to retrieve Google user profile.');
    }

    return UserProfile(
      userId: user.uid,
      name: user.displayName ?? account.displayName ?? 'FluentFlow Learner',
      email: user.email ?? account.email,
      photoUrl: user.photoURL,
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (_) {
      // Ignore if Google Sign-In was not initialized.
    }
    try {
      await _firebaseAuth?.signOut();
    } catch (_) {
      // Keep logout resilient by not rethrowing here.
    }
  }
}
