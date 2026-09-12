import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../models/call_model.dart';
import '../../models/history_model.dart';

/// Service for retrieving user call history from Cloud Firestore.
///
/// Accesses the subcollection at `/profile/{currentUserId}/history/` and maps
/// the stored call documents into [HistoryModel] and [CallModel].
class HomeService {
  HomeService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth? get firebaseAuth => _firebaseAuth;
  FirebaseFirestore? get firestore => _firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Sample call logs matching the UI mock for tests and offline preview.
  
  /// Retrieves the call history from `/profile/{currentUserId}` document `history` field.
  ///
  /// If [userId] is omitted, the currently authenticated user's UID is used.
  /// Returns a [HistoryModel] containing all calls sorted descending by [CallModel.createdAt].
  Future<HistoryModel> getCallHistory({String? userId}) async {


    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const HistoryModel(history: []);
    }

    final snapshot = await _db
        .collection('profile')
        .doc(uid)
        .collection('history')
        .get();

    final calls = snapshot.docs.map((doc) {
      final data = doc.data();
      return CallModel.fromJson({
        'id': doc.id,
        ...data,
      });
    }).toList();

    // Sort calls descending (most recent first)
    calls.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return HistoryModel(history: calls);
  }

  /// Convenience method returning a list of all [CallModel] instances for the given user.
  Future<List<CallModel>> getCalls({String? userId}) async {
    final historyModel = await getCallHistory(userId: userId);
    return historyModel.history;
  }

  /// Real-time stream of call history updates from `/profile/{currentUserId}/history/`.
  Stream<HistoryModel> watchCallHistory({String? userId}) {

    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return Stream.value(const HistoryModel(history: []));
    }

    return _db
        .collection('profile')
        .doc(uid)
        .collection('history')
        .snapshots()
        .map((snapshot) {
          final calls = snapshot.docs.map((doc) {
            final data = doc.data();
            return CallModel.fromJson({
              'id': doc.id,
              ...data,
            });
          }).toList();

          calls.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return HistoryModel(history: calls);
        });
  }

  /// Records a new call log under `/profile/{currentUserId}/history/`.
  Future<String> addCall(CallModel call, {String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('User is not authenticated.');
    }

    final docRef = await _db
        .collection('profile')
        .doc(uid)
        .collection('history')
        .add(call.toJson());

    return docRef.id;
  }

  /// Records a call log for both the caller and the receiver under:
  /// 1. `/profile/{userId}/history/` subcollection
  /// 2. `/profile/{userId}` document field `history: [ ... ]`
  Future<void> recordCallForBothUsers({
    required CallModel callerCall,
    required CallModel receiverCall,
    required String callerId,
    required String receiverId,
  }) async {
    if (_firestore == null && Firebase.apps.isEmpty) {
      return;
    }

    final batch = _db.batch();
    if (callerId.isNotEmpty) {
      final callerHistoryDoc = _db
          .collection('profile')
          .doc(callerId)
          .collection('history')
          .doc();
      batch.set(callerHistoryDoc, callerCall.toJson());
    }

    if (receiverId.isNotEmpty) {
      final receiverHistoryDoc = _db
          .collection('profile')
          .doc(receiverId)
          .collection('history')
          .doc();
      batch.set(receiverHistoryDoc, receiverCall.toJson());
    }

    await batch.commit();
  }
}

