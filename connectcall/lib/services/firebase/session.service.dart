import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/profile_model.dart';

/// Service for monitoring and checking active user authentication sessions
/// with Firebase Authentication and retrieving user profile data from Firestore.
class SessionService {
  SessionService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Returns true if a user is currently authenticated with Firebase.
  bool hasActiveSession() {
    try {
      return _auth.currentUser != null;
    } catch (_) {
      // Handles uninitialized Firebase instances gracefully (e.g. in test runners)
      return false;
    }
  }

  /// Convenience getter for whether a session is currently active.
  bool get isSessionActive => hasActiveSession();

  /// Gets the currently authenticated [User], or null if signed out or uninitialized.
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Asynchronously resolves the currently authenticated [User], waiting for
  /// Firebase Auth state restoration if the synchronous [currentUser] is temporarily null.
  Future<User?> resolveCurrentUser() async {
    var user = currentUser;
    if (user != null) return user;
    try {
      user = await _auth.authStateChanges().first.timeout(
            const Duration(milliseconds: 500),
            onTimeout: () => _auth.currentUser,
          );
    } catch (_) {}
    return user ?? currentUser;
  }

  /// Stream of user authentication state changes.
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Validates the current session by refreshing or reloading the Firebase token.
  /// Returns false if there is no user or if the token is invalid/revoked.
  Future<bool> validateSession() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      await user.getIdToken(true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves the active user's [ProfileModel] from Firestore, or null if no session.
  Future<ProfileModel?> getActiveProfile() async {
    try {
      final user = await resolveCurrentUser();
      if (user == null) return null;

      final doc = await _db.collection('profile').doc(user.uid).get();
      final data = doc.data();

      if (!doc.exists || data == null) {
        return null;
      }

      return ProfileModel.fromJson({
        'id': user.uid,
        ...data,
      });
    } catch (_) {
      return null;
    }
  }

  /// Updates the user's online presence status in Firestore under `/profile/{uid}`.
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = currentUser ?? await resolveCurrentUser();
      if (user == null) return;

      await _db.collection('profile').doc(user.uid).set(
        {
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Gracefully handle uninitialized Firebase or offline environments
    }
  }

  /// Terminates the current session by signing out from Firebase Auth.
  Future<void> signOut() async {
    try {
      await updateOnlineStatus(false);
      await _auth.signOut();
    } catch (_) {}
  }
}
