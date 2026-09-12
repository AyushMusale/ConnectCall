import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectcall/models/contacts_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../models/profile_model.dart';


/// Service for retrieving user profiles/contacts from Cloud Firestore.
///
/// Accesses the `/profile` collection to retrieve all user profile documents
/// and maps them into [ProfileModel] and [ContactsModel].
class ContactService {
  ContactService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  User? get _currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<User?> _resolveCurrentUser() async {
    var user = _currentUser;
    if (user == null) {
      try {
        if (Firebase.apps.isNotEmpty) {
          user = await _auth.authStateChanges().first.timeout(
            const Duration(milliseconds: 300),
            onTimeout: () => null,
          );
        }
      } catch (_) {
        user = null;
      }
    }
    return user;
  }

  bool _isSelf(
    ProfileModel profile,
    String docId, {
    required String? currentUid,
    required String? currentEmail,
    String? dataUid,
  }) {
    if (currentUid != null && currentUid.isNotEmpty) {
      if (profile.id == currentUid ||
          docId == currentUid ||
          (dataUid != null && dataUid == currentUid)) {
        return true;
      }
    }
    if (currentEmail != null && currentEmail.isNotEmpty) {
      final cleanEmail = currentEmail.trim().toLowerCase();
      if (profile.email.trim().toLowerCase() == cleanEmail) {
        return true;
      }
    }
    return false;
  }

  /// Retrieves all user profiles from the `/profile` collection,
  /// automatically removing the currently logged-in user directly at the service level.
  Future<List<ProfileModel>> getContacts() async {
    final user = await _resolveCurrentUser();
    final currentUid = user?.uid;
    final currentEmail = user?.email;
    
    final snapshot = await _db.collection('profile').get();

    final profiles = <ProfileModel>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final dataUid = (data['uid'] ?? data['userId'] ?? data['id']) as String?;
      final profile = ProfileModel.fromJson({
        'id': doc.id,
        ...data,
      });

      if (_isSelf(
        profile,
        doc.id,
        currentUid: currentUid,
        currentEmail: currentEmail,
        dataUid: dataUid,
      )) {
        continue;
      }
      profiles.add(profile);
    }

    return profiles;
  }

  /// Retrieves all user profiles wrapped in a [ContactsModel].
  Future<ContactsModel> getContactsModel() async {
    final list = await getContacts();
    return ContactsModel(contacts: list);
  }

  /// Real-time stream of user profiles from `/profile`,
  /// automatically excluding the current user.
  Stream<List<ProfileModel>> watchContacts() {
    return _db.collection('profile').snapshots().map((snapshot) {
      final user = _currentUser;
      final currentUid = user?.uid;
      final currentEmail = user?.email;

      final profiles = <ProfileModel>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dataUid =
            (data['uid'] ?? data['userId'] ?? data['id']) as String?;
        final profile = ProfileModel.fromJson({
          'id': doc.id,
          ...data,
        });

        if (_isSelf(
          profile,
          doc.id,
          currentUid: currentUid,
          currentEmail: currentEmail,
          dataUid: dataUid,
        )) {
          continue;
        }
        profiles.add(profile);
      }
      return profiles;
    });
  }

  /// Real-time stream of user contacts wrapped in a [ContactsModel].
  Stream<ContactsModel> watchContactsModel() {
    return watchContacts().map((contacts) => ContactsModel(contacts: contacts));
  }
}

