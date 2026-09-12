import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectcall/injection.dart';
import 'package:connectcall/services/firebase/signaling.service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Test double simulating Firestore behavior for SignalingService without extending sealed classes.
class TestableSignalingService extends SignalingService {
  final Map<String, Map<String, dynamic>> calls = {};
  final Map<String, List<Map<String, dynamic>>> callerCandidates = {};
  final Map<String, List<Map<String, dynamic>>> receiverCandidates = {};

  final StreamController<Map<String, dynamic>> callUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RTCIceCandidate> candidatesStreamController =
      StreamController<RTCIceCandidate>.broadcast();
  final StreamController<Map<String, dynamic>> incomingCallsStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  String? updatedStatusCallId;
  String? updatedStatus;

  @override
  Future<String> createCall({
    required String receiverId,
    RTCSessionDescription? offer,
    String? callerId,
    String? callerName,
    String? callerAvatar,
    String type = 'audio',
    String? callId,
  }) async {
    final id = (callId != null && callId.isNotEmpty) ? callId : 'call_generated_123';
    final data = <String, dynamic>{
      'id': id,
      'callerId': callerId ?? 'caller_me',
      'receiverId': receiverId,
      'type': type,
      'status': 'ringing',
      if (offer != null)
        'offer': {
          'sdp': offer.sdp,
          'type': offer.type,
        },
    };
    calls[id] = data;
    callUpdatesController.add(data);
    return id;
  }

  @override
  Future<void> sendAnswer({
    required String callId,
    required RTCSessionDescription answer,
    String status = 'ongoing',
  }) async {
    final existing = calls[callId] ?? <String, dynamic>{'id': callId};
    existing['status'] = status;
    existing['answer'] = {
      'sdp': answer.sdp,
      'type': answer.type,
    };
    calls[callId] = existing;
    callUpdatesController.add(existing);
  }

  @override
  Future<void> sendCandidate({
    required String callId,
    required RTCIceCandidate candidate,
    bool isCaller = true,
  }) async {
    final list = isCaller
        ? callerCandidates.putIfAbsent(callId, () => [])
        : receiverCandidates.putIfAbsent(callId, () => []);
    list.add({
      'candidate': candidate.candidate,
      'sdp': candidate.sdpMid,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  @override
  StreamSubscription<RTCIceCandidate> listenForCandidates({
    required String callId,
    required bool isCaller,
    required void Function(RTCIceCandidate candidate) onCandidate,
    void Function(Object error)? onError,
  }) {
    return candidatesStreamController.stream.listen(onCandidate, onError: onError);
  }

  @override
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      listenForIncomingCalls({
    String? receiverId,
    required void Function(DocumentSnapshot<Map<String, dynamic>> callDoc)
        onIncomingCall,
    void Function(Object error)? onError,
  }) {
    final emptySubController =
        StreamController<QuerySnapshot<Map<String, dynamic>>>();
    incomingCallsStreamController.stream.listen((callData) {
      // In tests, signal receipt
    }, onError: onError);
    return emptySubController.stream.listen(null);
  }

  @override
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

    final sub = callUpdatesController.stream.listen(
      (data) {
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
          if (answer is Map<String, dynamic> && answer['sdp'] != null) {
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
          if (offer is Map<String, dynamic> && offer['sdp'] != null) {
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

    // Return dummy subscription conforming to the return type
    final controller = StreamController<DocumentSnapshot<Map<String, dynamic>>>();
    controller.onCancel = sub.cancel;
    return controller.stream.listen(null);
  }

  @override
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    updatedStatusCallId = callId;
    updatedStatus = status;
    final existing = calls[callId] ?? <String, dynamic>{'id': callId};
    existing['status'] = status;
    calls[callId] = existing;
    callUpdatesController.add(existing);
  }

  Future<void> close() async {
    await callUpdatesController.close();
    await candidatesStreamController.close();
    await incomingCallsStreamController.close();
  }
}

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  group('SignalingService Clean Architecture Tests', () {
    late TestableSignalingService signaling;

    setUp(() {
      signaling = TestableSignalingService();
    });

    tearDown(() async {
      await signaling.close();
    });

    group('CALL SETUP', () {
      test('createCall / sendOffer initiates a call document', () async {
        final offer = RTCSessionDescription('sdp_offer_abc', 'offer');
        final callId = await signaling.createCall(
          receiverId: 'user_recipient',
          offer: offer,
          callerId: 'user_caller',
          type: 'video',
        );

        expect(callId, isNotEmpty);
        expect(signaling.calls[callId]?['status'], equals('ringing'));
        expect(signaling.calls[callId]?['type'], equals('video'));
        expect(signaling.calls[callId]?['receiverId'], equals('user_recipient'));

        // Test sendOffer alias
        final aliasCallId = await signaling.sendOffer(
          receiverId: 'user_recipient_2',
          offer: offer,
          callerId: 'user_caller',
        );
        expect(aliasCallId, isNotEmpty);
        expect(signaling.calls[aliasCallId]?['receiverId'], equals('user_recipient_2'));
      });

      test('sendAnswer updates call document with answer SDP and ongoing status', () async {
        final offer = RTCSessionDescription('sdp_offer', 'offer');
        final callId = await signaling.createCall(
          receiverId: 'user_recipient',
          offer: offer,
        );

        final answer = RTCSessionDescription('sdp_answer', 'answer');
        await signaling.sendAnswer(callId: callId, answer: answer);

        expect(signaling.calls[callId]?['status'], equals('ongoing'));
        expect(signaling.calls[callId]?['answer']?['sdp'], equals('sdp_answer'));
        expect(signaling.calls[callId]?['answer']?['type'], equals('answer'));
      });
    });

    group('ICE', () {
      test('sendCandidate saves caller and receiver candidates', () async {
        const callId = 'call_ice_test';
        final candidate = RTCIceCandidate('candidate_foo', 'audio', 0);

        await signaling.sendCandidate(
          callId: callId,
          candidate: candidate,
          isCaller: true,
        );
        expect(signaling.callerCandidates[callId]?.length, equals(1));
        expect(signaling.callerCandidates[callId]?.first['candidate'], equals('candidate_foo'));

        await signaling.sendCandidate(
          callId: callId,
          candidate: candidate,
          isCaller: false,
        );
        expect(signaling.receiverCandidates[callId]?.length, equals(1));
        expect(signaling.receiverCandidates[callId]?.first['candidate'], equals('candidate_foo'));
      });

      test('listenForCandidates receives incoming candidates', () async {
        final received = <RTCIceCandidate>[];
        final sub = signaling.listenForCandidates(
          callId: 'call_ice_123',
          isCaller: true,
          onCandidate: received.add,
        );

        signaling.candidatesStreamController.add(
          RTCIceCandidate('candidate_stream_test', '0', 0),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(received.length, equals(1));
        expect(received.first.candidate, equals('candidate_stream_test'));
        await sub.cancel();
      });
    });

    group('CALL LISTENING', () {
      test('listenToCall invokes callbacks on answer, offer, and status changes', () async {
        RTCSessionDescription? answerReceived;
        RTCSessionDescription? offerReceived;
        String? statusReceived;
        Map<String, dynamic>? dataReceived;

        final sub = signaling.listenToCall(
          callId: 'call_listen_test',
          onAnswer: (a) => answerReceived = a,
          onOffer: (o) => offerReceived = o,
          onStatusChanged: (s) => statusReceived = s,
          onData: (d) => dataReceived = d,
        );

        // Initial offer state
        signaling.callUpdatesController.add({
          'id': 'call_listen_test',
          'status': 'ringing',
          'offer': {
            'sdp': 'sdp_offer_val',
            'type': 'offer',
          },
        });
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(statusReceived, equals('ringing'));
        expect(offerReceived?.sdp, equals('sdp_offer_val'));
        expect(dataReceived?['id'], equals('call_listen_test'));

        // Update with answer
        signaling.callUpdatesController.add({
          'id': 'call_listen_test',
          'status': 'ongoing',
          'answer': {
            'sdp': 'sdp_answer_val',
            'type': 'answer',
          },
        });
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(statusReceived, equals('ongoing'));
        expect(answerReceived?.sdp, equals('sdp_answer_val'));
        await sub.cancel();
      });
    });

    group('CALL STATE', () {
      test('updateCallStatus updates document status', () async {
        await signaling.updateCallStatus(
          callId: 'call_state_test',
          status: 'ended',
        );

        expect(signaling.updatedStatusCallId, equals('call_state_test'));
        expect(signaling.updatedStatus, equals('ended'));
      });
    });
  });
}
