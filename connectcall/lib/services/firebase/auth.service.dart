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
        profile.toJson(),
      );
      await batch.commit();
      return profile;
    } catch (_) {
      // Do not leave an auth account without its corresponding profile data.
      await firebaseUser.delete();
      rethrow;
    }
  }
}
