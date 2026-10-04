import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Errors that mean the auth backend itself is unreachable or not configured (not a bad credential).
  static const Set<String> _backendUnavailableCodes = {
    'network-request-failed',
    'operation-not-allowed',
    'configuration-not-found',
    'app-not-authorized',
    'internal-error',
  };

  /// True when the failure is about the user's credentials and sign in must be refused.
  static bool isCredentialError(Object error) =>
      error is FirebaseAuthException && !_backendUnavailableCodes.contains(error.code);

  /// Initializes Firebase SDK with error handling and fallback for non-configured platforms.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint('[FirebaseService] Firebase initialized successfully with DefaultFirebaseOptions.');
    } catch (e) {
      _isInitialized = false;
      debugPrint('[FirebaseService] Firebase initialization deferred or fallback: $e');
    }
  }

  /// Sign in with Firebase Auth or fallback to demo auth
  static Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    if (!_isInitialized) {
      debugPrint('[FirebaseService] Using fallback demo sign in mode for $email');
      return null;
    }
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      debugPrint('[FirebaseService] Auth error: $e');
      rethrow;
    }
  }

  /// Register / Sign up with Firebase Auth
  static Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    if (!_isInitialized) {
      debugPrint('[FirebaseService] Using fallback demo registration mode for $email');
      return null;
    }
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      debugPrint('[FirebaseService] Registration error: $e');
      rethrow;
    }
  }

  /// Sign out current user from Firebase Auth
  static Future<void> signOut() async {
    if (!_isInitialized) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('[FirebaseService] Sign out error: $e');
    }
  }

  /// Current Firebase Auth User
  static User? get currentUser {
    if (!_isInitialized) return null;
    return FirebaseAuth.instance.currentUser;
  }
}
