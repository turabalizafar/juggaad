import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web sign-in using a popup
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      } else {
        // Mobile sign-in using google_sign_in 7.x API
        if (!_initialized) {
          const String webClientId = '968327078807-4bdrteo25acsl4rkq930rgos9mlpe14j.apps.googleusercontent.com';
          await GoogleSignIn.instance.initialize(serverClientId: webClientId);
          _initialized = true;
        }

        // authenticate() throws GoogleSignInException on cancel/failure
        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();

        // In google_sign_in 7.x, .authentication is a sync getter
        // that only provides idToken (auth and authz are separated)
        final GoogleSignInAuthentication googleAuth =
            googleUser.authentication;

        // For Firebase Auth, idToken alone is sufficient
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } on GoogleSignInException catch (e) {
      // User cancelled the sign-in flow
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        debugPrint('Google sign in cancelled by user');
        return null;
      }
      debugPrint('Google sign in error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      // Ignore if Google Sign-In disconnect fails
    }
    await _auth.signOut();
  }
}
