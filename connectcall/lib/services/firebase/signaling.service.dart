import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Service for managing WebRTC call signaling through Cloud Firestore.
class SignalingService {
  SignalingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _firebaseAuth;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  // ==========================================
  // CALL SETUP
  // ==========================================

  /// Creates a call document under `/calls/{callId}` (optionally with an initial SDP offer).
  Future<String> createCall({
    required String receiverId,
    RTCSessionDescription? offer,
    String? callerId,
    String type = 'audio',
    String? callId,
  }) async {
    try {
      final effectiveCallerId = callerId ?? _auth.currentUser?.uid ?? '';
      final docRef = (callId != null && callId.isNotEmpty)
          ? _db.collection('calls').doc(callId)
          : _db.collection('calls').doc();

      final callData = <String, dynamic>{
        'id': docRef.id,
        'callerId': effectiveCallerId,
        'receiverId': receiverId,
        'type': type,
        'status': 'ringing',
        'createdAt': FieldValue.serverTimestamp(),
        if (offer != null)
          'offer': {
            'sdp': offer.sdp,
            'type': offer.type,
          },
      };

      await docRef.set(callData, SetOptions(merge: true));
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Sends an SDP offer to an existing call document `/calls/{callId}`,
  /// or creates a call document with the offer.
  Future<String> sendOffer({
    String? callId,
    required RTCSessionDescription offer,
    String? receiverId,
    String? callerId,
    String type = 'audio',
  }) async {
    try {
      if (callId != null && callId.isNotEmpty) {
        await _db.collection('calls').doc(callId).set({
          'offer': {
            'sdp': offer.sdp,
            'type': offer.type,
          },
        }, SetOptions(merge: true));
        return callId;
      } else if (receiverId != null) {
        return createCall(
          receiverId: receiverId,
          offer: offer,
          callerId: callerId,
          type: type,
        );
      } else {
        throw ArgumentError(
          'Either callId or receiverId must be provided to sendOffer.',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Sends an answer for the given [callId] by updating `/calls/{callId}` with the answer SDP.
  Future<void> sendAnswer({
    required String callId,
    required RTCSessionDescription answer,
    String status = 'ongoing',
  }) async {
    try {
      await _db.collection('calls').doc(callId).update({
        'status': status,
        'answer': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // ICE
  // ==========================================

  /// Sends an ICE candidate to Firestore under `/calls/{callId}/{callerCandidates|receiverCandidates}`.
  Future<void> sendCandidate({
    required String callId,
    required RTCIceCandidate candidate,
    bool isCaller = true,
  }) async {
    try {
      final subcollection =
          isCaller ? 'callerCandidates' : 'receiverCandidates';
      final candidateData = <String, dynamic>{
        'candidate': candidate.candidate,
        'sdp': candidate.sdpMid,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      };

      await _db
          .collection('calls')
          .doc(callId)
          .collection(subcollection)
          .add(candidateData);
    } catch (e) {
      rethrow;
    }
  }

  /// Listens for remote ICE candidates:
  /// - When [isCaller] is true, listens to candidates sent by the recipient (`receiverCandidates`).
  /// - When [isCaller] is false, listens to candidates sent by the caller (`callerCandidates`).
  StreamSubscription<RTCIceCandidate> listenForCandidates({
    required String callId,
    required bool isCaller,
    required void Function(RTCIceCandidate candidate) onCandidate,
    void Function(Object error)? onError,
  }) {
    final subcollection =
        isCaller ? 'receiverCandidates' : 'callerCandidates';
    return _db
        .collection('calls')
        .doc(callId)
        .collection(subcollection)
        .snapshots()
        .expand((snapshot) {
      final candidates = <RTCIceCandidate>[];
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['candidate'] != null) {
            candidates.add(
              RTCIceCandidate(
                data['candidate'] as String?,
                (data['sdpMid'] ?? data['sdp']) as String?,
                (data['sdpMLineIndex'] as num?)?.toInt(),
              ),
            );
          }
        }
      }
      return candidates;
    }).listen(onCandidate, onError: onError);
  }

  // ==========================================
  // CALL LISTENING
  // ==========================================

  /// Listens for incoming calls where `receiverId` equals [receiverId]
  /// (or current authenticated user) with status 'ringing'.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      listenForIncomingCalls({
    required void Function(DocumentSnapshot<Map<String, dynamic>> callDoc)
        onIncomingCall,
    void Function(Object error)? onError,
  }) {
    try {
      final effectiveReceiverId = _auth.currentUser?.uid ?? '';
      return _db
          .collection('calls')
          .where('receiverId', isEqualTo: effectiveReceiverId)
          .where('status', isEqualTo: 'ringing')
          .snapshots()
          .listen(
        (snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              onIncomingCall(change.doc);
            }
          }
        },
        onError: onError,
      );
    } catch (e) {
      onError?.call(e);
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty().listen(null);
    }
  }

  /// Listens to `/calls/{callId}` document updates, invoking callbacks for:
  /// - [onAnswer]: when remote answer is received.
  /// - [onOffer]: when remote offer is received.
  /// - [onStatusChanged]: when call status changes.
  /// - [onData]: on every raw document update.
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> listenToCall({
    required String callId,
    void Function(RTCSessionDescription answer)? onAnswer,
    void Function(RTCSessionDescription offer)? onOffer,
    void Function(String status)? onStatusChanged,
    void Function(Map<String, dynamic> data)? onData,
    void Function(Object error)? onError,
  }) {
    String? previousStatus;
    bool answerReceived = false;
    bool offerReceived = false;

    return _db.collection('calls').doc(callId).snapshots().listen(
      (snapshot) {
        final data = snapshot.data();
        if (data == null) return;

        if (onData != null) {
          onData(data);
        }

        final status = (data['status'] as String?) ?? '';
        if (onStatusChanged != null && status != previousStatus) {
          previousStatus = status;
          onStatusChanged(status);
        }

        if (onAnswer != null && !answerReceived) {
          final answer = data['answer'];
          if (answer is Map && answer['sdp'] != null) {
            answerReceived = true;
            onAnswer(
              RTCSessionDescription(
                answer['sdp'] as String?,
                answer['type'] as String?,
              ),
            );
          }
        }

        if (onOffer != null && !offerReceived) {
          final offer = data['offer'];
          if (offer is Map && offer['sdp'] != null) {
            offerReceived = true;
            onOffer(
              RTCSessionDescription(
                offer['sdp'] as String?,
                offer['type'] as String?,
              ),
            );
          }
        }
      },
      onError: onError,
    );
  }

  // ==========================================
  // CALL STATE
  // ==========================================

  /// Updates the status of a call document (e.g. 'ringing', 'ongoing', 'ended', 'rejected', 'missed').
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    try {
      await _db.collection('calls').doc(callId).update({
        'status': status,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves a call document by [callId].
  Future<DocumentSnapshot<Map<String, dynamic>>> getCall(String callId) async {
    try {
      return await _db.collection('calls').doc(callId).get();
    } catch (e) {
      rethrow;
    }
  }
}
