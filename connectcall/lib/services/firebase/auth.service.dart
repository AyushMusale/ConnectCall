import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/profile_model.dart';
import '../../models/user_model.dart';

/// Handles authentication and the matching Firestore user documents.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<ProfileModel> signUp(String name, UserModel user) async {
    final displayName = name.trim();
    final email = user.email.trim();

    if (displayName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Name cannot be empty.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: user.password,
    );
    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw StateError('Firebase did not return a user after sign-up.');
    }

    final profile = ProfileModel(
      id: firebaseUser.uid,
      name: displayName,
      email: email,
    );

    try {
      final batch = _db.batch();
      batch.set(
        _db.collection('profile').doc(firebaseUser.uid),
        {
          'id': profile.id,
          'name': profile.name,
          'email': profile.email,
          'namelower': profile.name.toLowerCase(),
        },
      );
      await batch.commit();
      return profile;
    } catch (_) {
      // Do not leave an auth account without its corresponding profile data.
      await firebaseUser.delete();
      rethrow;
    }
  }

  /// Returns true if a user currently has an active authentication session.
  bool hasActiveSession() {
    try {
      return _auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Convenience getter for active session status.
  bool get isSessionActive => hasActiveSession();

  /// Gets the currently authenticated [User], or null if signed out.
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Stream of user authentication state changes.
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Retrieves the active user's [ProfileModel] from Firestore, or null if no session.
  Future<ProfileModel?> getActiveProfile() async {
    try {
      final user = currentUser;
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
}
