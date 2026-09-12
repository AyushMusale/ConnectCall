import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectcall/services/calls.service.dart';
import 'package:connectcall/services/firebase/signaling.service.dart';
import 'package:connectcall/services/webRTC.service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MockPeerConnection extends Fake implements RTCPeerConnection {
  void Function(RTCTrackEvent)? capturedOnTrack;
  void Function(MediaStream)? capturedOnAddStream;
  bool isDisposed = false;

  @override
  set onTrack(void Function(RTCTrackEvent)? callback) {
    capturedOnTrack = callback;
  }

  @override
  set onAddStream(void Function(MediaStream)? callback) {
    capturedOnAddStream = callback;
  }

  @override
  Future<void> close() async {
    isDisposed = true;
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }
}

class FakeWebRTCService extends WebRTCService {
  final mockPc = MockPeerConnection();
  bool audioOnlyAdded = false;
  bool audioVideoAdded = false;
  bool offerCreated = false;
  RTCSessionDescription? setRemoteDesc;
  final List<RTCIceCandidate> remoteCandidates = [];
  void Function(RTCIceCandidate)? candidateCallback;

  @override
  Future<RTCPeerConnection> createPeerConnectionOnly({
    Map<String, dynamic>? configuration,
    Map<String, dynamic>? constraints,
  }) async {
    return mockPc;
  }

  @override
  Future<void> addAudioOnlyLocalStream(
    RTCPeerConnection peerConnection, {
    Map<String, dynamic>? constraints,
  }) async {
    audioOnlyAdded = true;
  }

  @override
  Future<void> addAudioAndVideoLocalStream(
    RTCPeerConnection peerConnection, {
    Map<String, dynamic>? constraints,
  }) async {
    audioVideoAdded = true;
  }

  @override
  Future<RTCSessionDescription> createOffer(
    RTCPeerConnection peerConnection, {
    Map<String, dynamic>? constraints,
  }) async {
    offerCreated = true;
    return RTCSessionDescription('dummy_offer_sdp', 'offer');
  }

  @override
  Future<void> setRemoteDescription(
    RTCPeerConnection peerConnection,
    RTCSessionDescription description,
  ) async {
    setRemoteDesc = description;
  }

  @override
  void onIceCandidate(
    RTCPeerConnection peerConnection,
    void Function(RTCIceCandidate candidate) onCandidate,
  ) {
    candidateCallback = onCandidate;
  }

  @override
  Future<void> addCandidate(
    RTCPeerConnection peerConnection,
    RTCIceCandidate candidate,
  ) async {
    remoteCandidates.add(candidate);
  }

  @override
  Future<void> dispose() async {
    await mockPc.dispose();
  }
}

class FakeSignalingServiceForCalls extends SignalingService {
  String? createdForReceiver;
  RTCSessionDescription? createdOffer;
  String? createdCallType;
  String? offerSentCallId;
  RTCSessionDescription? sentOffer;
  final List<RTCIceCandidate> sentCandidates = [];
  String? updatedStatus;

  void Function(RTCSessionDescription answer)? capturedOnAnswer;
  void Function(String status)? capturedOnStatusChanged;
  void Function(RTCIceCandidate candidate)? capturedOnRemoteCandidate;

  // Execution order tracker to verify user's sequence
  final List<String> executionSteps = [];

  @override
  Future<String> createCall({
    required String receiverId,
    RTCSessionDescription? offer,
    String? callerId,
    String type = 'audio',
    String? callId,
  }) async {
    executionSteps.add('create call document');
    createdForReceiver = receiverId;
    createdOffer = offer;
    createdCallType = type;
    return 'call_test_999';
  }

  @override
  Future<String> sendOffer({
    String? callId,
    required RTCSessionDescription offer,
    String? receiverId,
    String? callerId,
    String type = 'audio',
  }) async {
    executionSteps.add('send offer to calls/{callId}');
    offerSentCallId = callId;
    sentOffer = offer;
    return callId ?? 'call_test_999';
  }

  @override
  Future<void> sendCandidate({
    required String callId,
    required RTCIceCandidate candidate,
    bool isCaller = true,
  }) async {
    sentCandidates.add(candidate);
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
    capturedOnAnswer = onAnswer;
    capturedOnStatusChanged = onStatusChanged;
    final controller = StreamController<DocumentSnapshot<Map<String, dynamic>>>();
    return controller.stream.listen(null);
  }

  @override
  StreamSubscription<RTCIceCandidate> listenForCandidates({
    required String callId,
    required bool isCaller,
    required void Function(RTCIceCandidate candidate) onCandidate,
    void Function(Object error)? onError,
  }) {
    capturedOnRemoteCandidate = onCandidate;
    final controller = StreamController<RTCIceCandidate>();
    return controller.stream.listen(null);
  }

  @override
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    updatedStatus = status;
  }
}

void main() {
  group('CallsService Tests', () {
    late FakeWebRTCService fakeWebRTC;
    late FakeSignalingServiceForCalls fakeSignaling;
    late CallsService callsService;

    setUp(() {
      fakeWebRTC = FakeWebRTCService();
      fakeSignaling = FakeSignalingServiceForCalls();
      callsService = CallsService(
        webRTCService: fakeWebRTC,
        signalingService: fakeSignaling,
      );
    });

    test('startCall executes the exact required WebRTC setup sequence', () async {
      String? callStatus;
      final callId = await callsService.startCall(
        'recipient_user_456',
        isVideo: false,
        onCallStatusChanged: (status) => callStatus = status,
      );

      // Verify sequence: create call document -> ... -> send offer to calls/{callId}
      expect(fakeSignaling.executionSteps, equals([
        'create call document',
        'send offer to calls/{callId}',
      ]));

      // Verify returned callId
      expect(callId, equals('call_test_999'));
      expect(callsService.currentCallId, equals('call_test_999'));

      // Verify WebRTC tracks added and offer created
      expect(fakeWebRTC.audioOnlyAdded, isTrue);
      expect(fakeWebRTC.audioVideoAdded, isFalse);
      expect(fakeWebRTC.offerCreated, isTrue);

      // Verify call document created first
      expect(fakeSignaling.createdForReceiver, equals('recipient_user_456'));
      expect(fakeSignaling.createdCallType, equals('audio'));

      // Verify offer sent with callId
      expect(fakeSignaling.offerSentCallId, equals('call_test_999'));
      expect(fakeSignaling.sentOffer?.sdp, equals('dummy_offer_sdp'));

      // Verify sending local ICE candidates with callId
      expect(fakeWebRTC.candidateCallback, isNotNull);
      final localCandidate = RTCIceCandidate('cand_123', 'audio', 0);
      fakeWebRTC.candidateCallback!(localCandidate);
      expect(fakeSignaling.sentCandidates.length, equals(1));
      expect(fakeSignaling.sentCandidates.first.candidate, equals('cand_123'));

      // Verify receiving remote answer
      expect(fakeSignaling.capturedOnAnswer, isNotNull);
      final remoteAnswer = RTCSessionDescription('remote_answer_sdp', 'answer');
      fakeSignaling.capturedOnAnswer!(remoteAnswer);
      expect(fakeWebRTC.setRemoteDesc?.sdp, equals('remote_answer_sdp'));

      // Verify receiving remote ICE candidates
      expect(fakeSignaling.capturedOnRemoteCandidate, isNotNull);
      final remoteCandidate = RTCIceCandidate('cand_remote', 'audio', 0);
      fakeSignaling.capturedOnRemoteCandidate!(remoteCandidate);
      expect(fakeWebRTC.remoteCandidates.length, equals(1));
      expect(fakeWebRTC.remoteCandidates.first.candidate, equals('cand_remote'));

      // Verify status change callback
      expect(fakeSignaling.capturedOnStatusChanged, isNotNull);
      fakeSignaling.capturedOnStatusChanged!('ongoing');
      expect(callStatus, equals('ongoing'));
    });

    test('startCall with isVideo: true sets up video and audio tracks', () async {
      await callsService.startCall(
        'recipient_user_789',
        isVideo: true,
      );

      expect(fakeWebRTC.audioVideoAdded, isTrue);
      expect(fakeSignaling.createdCallType, equals('video'));
    });

    test('endCall updates status in Firestore and disposes WebRTC', () async {
      await callsService.startCall('user_abc');
      expect(callsService.currentCallId, equals('call_test_999'));

      await callsService.endCall();
      expect(fakeSignaling.updatedStatus, equals('ended'));
      expect(callsService.currentCallId, isNull);
      expect(fakeWebRTC.mockPc.isDisposed, isTrue);
    });
  });
}
