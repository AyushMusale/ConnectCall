import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/profile_model.dart';
import '../../models/user_model.dart';

/// Service for handling user login with Firebase Authentication and Firestore profile retrieval.
class LoginService {
  LoginService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Logs in a user using [UserModel] and retrieves their [ProfileModel] from Firestore.
  Future<ProfileModel> loginWithEmailAndPassword(UserModel user) async {
    final email = user.email.trim();

    if (email.isEmpty) {
      throw ArgumentError.value(user.email, 'email', 'Email cannot be empty.');
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: user.password,
    );
    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw StateError('Firebase did not return a user after login.');
    }

    final doc =
        await _db.collection('profile').doc(firebaseUser.uid).get();
    final data = doc.data();

    if (!doc.exists || data == null) {
      throw StateError('Profile not found for user: ${firebaseUser.uid}');
    }

    return ProfileModel.fromJson({
      'id': firebaseUser.uid,
      ...data,
    });
  }

  /// Logs in a user using [UserModel] and retrieves their [ProfileModel] from Firestore.
  Future<ProfileModel> login(UserModel user) {
    return loginWithEmailAndPassword(user);
  }

  /// Logs out the currently authenticated user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Stream of user authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Gets the currently authenticated user.
  User? get currentUser => _auth.currentUser;
}
