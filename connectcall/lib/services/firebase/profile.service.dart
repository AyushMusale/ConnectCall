import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/profile_model.dart';

/// Service for managing user profile details in Firestore and Firebase Auth,
/// including updating display name, avatar, retrieving profile data,
/// and signing out.
class ProfileService {
  ProfileService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Gets the currently authenticated [User], or null if signed out or uninitialized.
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Asynchronously resolves current authenticated [User].
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

  /// Retrieves the current user's profile details from Firestore.
  /// Falls back to FirebaseAuth details if Firestore document is absent.
  Future<ProfileModel?> getProfile() async {
    try {
      final user = await resolveCurrentUser();
      if (user == null) return null;

      final doc = await _db.collection('profile').doc(user.uid).get();
      final data = doc.data();

      if (doc.exists && data != null) {
        return ProfileModel.fromJson({
          'id': user.uid,
          ...data,
        });
      }

      // Fallback to Firebase user data
      return ProfileModel(
        id: user.uid,
        name: user.displayName?.isNotEmpty == true
            ? user.displayName!
            : (user.email?.split('@').first ?? 'User'),
        email: user.email ?? '',
        avatar: user.photoURL,
      );
    } catch (_) {
      final user = currentUser;
      if (user != null) {
        return ProfileModel(
          id: user.uid,
          name: user.displayName ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
          avatar: user.photoURL,
        );
      }
      return null;
    }
  }

  /// Real-time stream of the current user's profile.
  Stream<ProfileModel?> watchProfile() async* {
    final user = await resolveCurrentUser();
    if (user == null) {
      yield null;
      return;
    }

    try {
      yield* _db.collection('profile').doc(user.uid).snapshots().map((doc) {
        final data = doc.data();
        if (doc.exists && data != null) {
          return ProfileModel.fromJson({
            'id': user.uid,
            ...data,
          });
        }
        return ProfileModel(
          id: user.uid,
          name: user.displayName ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
          avatar: user.photoURL,
        );
      });
    } catch (_) {
      yield await getProfile();
    }
  }

  /// Updates the user's name in Firestore (`name` and `namelower`) and Firebase Auth.
  /// Validates that [newName] is not empty.
  Future<ProfileModel> updateName(String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(newName, 'name', 'Name cannot be empty.');
    }

    final user = await resolveCurrentUser();
    if (user == null) {
      throw StateError('No authenticated user found to update profile.');
    }

    // 1. Update Firestore profile document
    await _db.collection('profile').doc(user.uid).set(
      {
        'id': user.uid,
        'name': trimmedName,
        'namelower': trimmedName.toLowerCase(),
        'email': user.email ?? '',
      },
      SetOptions(merge: true),
    );

    // 2. Update Firebase Auth display name
    try {
      await user.updateDisplayName(trimmedName);
    } catch (_) {}

    final currentDoc = await getProfile();
    return currentDoc?.copyWith(name: trimmedName) ??
        ProfileModel(
          id: user.uid,
          name: trimmedName,
          email: user.email ?? '',
          avatar: user.photoURL,
        );
  }

  /// Updates the user's avatar URL in Firestore and Firebase Auth.
  Future<ProfileModel> updateAvatar(String avatarUrl) async {
    final trimmedUrl = avatarUrl.trim();
    final user = await resolveCurrentUser();
    if (user == null) {
      throw StateError('No authenticated user found to update avatar.');
    }

    // 1. Update Firestore profile document
    await _db.collection('profile').doc(user.uid).set(
      {
        'avatar': trimmedUrl,
      },
      SetOptions(merge: true),
    );

    // 2. Update Firebase Auth photo URL
    try {
      await user.updatePhotoURL(trimmedUrl);
    } catch (_) {}

    final currentDoc = await getProfile();
    return currentDoc?.copyWith(avatar: trimmedUrl) ??
        ProfileModel(
          id: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          avatar: trimmedUrl,
        );
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
