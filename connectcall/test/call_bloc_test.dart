import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectcall/models/call_model.dart';
import 'package:connectcall/screens/call/bloc/call_bloc.dart';
import 'package:connectcall/services/calls.service.dart';
import 'package:connectcall/services/firebase/history.service.dart';
import 'package:connectcall/services/firebase/session.service.dart';
import 'package:connectcall/services/firebase/signaling.service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MockCallsService extends CallsService {
  String? lastStartedUserId;
  String? lastCallType;
  void Function(String status)? lastStatusCallback;
  bool callEnded = false;
  String? lastEndStatus;

  @override
  Future<String> startCall(
    String otherUserId, {
    String type = 'audio',
    bool isVideo = false,
    void Function(MediaStream remoteStream)? onRemoteStream,
    void Function(String status)? onCallStatusChanged,
  }) async {
    lastStartedUserId = otherUserId;
    lastCallType = type;
    lastStatusCallback = onCallStatusChanged;
    return 'call_test_123';
  }

  @override
  Future<void> endCall({String status = 'ended'}) async {
    callEnded = true;
    lastEndStatus = status;
  }
}

class MockSignalingService extends SignalingService {
  String? lastUpdatedCallId;
  String? lastUpdatedStatus;

  @override
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    lastUpdatedCallId = callId;
    lastUpdatedStatus = status;
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
    final controller =
        StreamController<DocumentSnapshot<Map<String, dynamic>>>();
    return controller.stream.listen((_) {});
  }
}

class MockHistoryService extends HistoryService {
  final List<Map<String, dynamic>> recordedCalls = [];

  @override
  Future<void> recordCallForBothUsers({
    required CallModel callerCall,
    required CallModel receiverCall,
    required String callerId,
    required String receiverId,
  }) async {
    recordedCalls.add({
      'callerId': callerId,
      'receiverId': receiverId,
      'callerCall': callerCall,
      'receiverCall': receiverCall,
    });
  }
}

class MockSessionService extends SessionService {
  @override
  bool hasActiveSession() => true;
}

void main() {
  group('CallBloc Unit Tests', () {
    late MockCallsService mockCallsService;
    late MockSignalingService mockSignalingService;
    late MockHistoryService mockHistoryService;
    late MockSessionService mockSessionService;

    setUp(() {
      mockCallsService = MockCallsService();
      mockSignalingService = MockSignalingService();
      mockHistoryService = MockHistoryService();
      mockSessionService = MockSessionService();
    });

    test('CallStartRequested initiates call, emits ringing state with 30s countdown', () async {
      final bloc = CallBloc(
        callsService: mockCallsService,
        signalingService: mockSignalingService,
        historyService: mockHistoryService,
        sessionService: mockSessionService,
      );

      bloc.add(const CallStartRequested(
        otherUserId: 'user_bob',
        otherUserName: 'Bob Smith',
        otherUserAvatar: 'https://example.com/bob.png',
        type: 'audio',
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<CallState>((state) {
          return state.isRinging &&
              state.otherUserId == 'user_bob' &&
              state.otherUserName == 'Bob Smith' &&
              state.callId == 'call_test_123';
        })),
      );

      expect(mockCallsService.lastStartedUserId, 'user_bob');
      expect(mockCallsService.lastCallType, 'audio');

      await bloc.close();
    });

    test('Timeout after unanswered duration changes status to missed and records history for both users with duration 0', () async {
      final bloc = CallBloc(
        callsService: mockCallsService,
        signalingService: mockSignalingService,
        historyService: mockHistoryService,
        sessionService: mockSessionService,
        timeoutDuration: const Duration(milliseconds: 100),
      );

      bloc.add(const CallStartRequested(
        otherUserId: 'user_alice',
        otherUserName: 'Alice Wonderland',
        type: 'video',
      ));

      // Wait for the 100ms timeout to trigger CallTimeoutMissed
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<CallState>((state) {
          return state.isMissed && state.ringRemainingSeconds == 0;
        })),
      );

      // Verify Firestore status updated to 'missed'
      expect(mockSignalingService.lastUpdatedStatus, 'missed');
      expect(mockCallsService.lastEndStatus, 'missed');

      // Verify history was recorded for both users
      expect(mockHistoryService.recordedCalls.length, 1);
      final entry = mockHistoryService.recordedCalls.first;
      expect(entry['receiverId'], 'user_alice');

      final callerCall = entry['callerCall'] as CallModel;
      final receiverCall = entry['receiverCall'] as CallModel;

      expect(callerCall.status, 'missed');
      expect(callerCall.duration, 0);
      expect(callerCall.otherUserId, 'user_alice');
      expect(callerCall.type, 'video');

      expect(receiverCall.status, 'missed');
      expect(receiverCall.duration, 0);
      expect(receiverCall.type, 'video');

      await bloc.close();
    });

    test('CallAccepted starts duration timer and stops 30s countdown', () async {
      final bloc = CallBloc(
        callsService: mockCallsService,
        signalingService: mockSignalingService,
        historyService: mockHistoryService,
        sessionService: mockSessionService,
        timeoutDuration: const Duration(seconds: 30),
      );

      bloc.add(const CallStartRequested(
        otherUserId: 'user_charlie',
        otherUserName: 'Charlie',
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<CallState>((s) => s.isRinging)),
      );

      // Simulate receiver accepting the call
      bloc.add(const CallAccepted());

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<CallState>((s) => s.isOngoing && s.durationSeconds == 0)),
      );

      // Trigger duration tick
      bloc.add(const CallTimerTicked(5));
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<CallState>((s) => s.isOngoing && s.durationSeconds == 5)),
      );

      expect(bloc.state.formattedDuration, '00:05');

      await bloc.close();
    });

    test('Ending call records history with duration, outgoing for caller and incoming for receiver', () async {
      final bloc = CallBloc(
        callsService: mockCallsService,
        signalingService: mockSignalingService,
        historyService: mockHistoryService,
        sessionService: mockSessionService,
      );

      bloc.add(const CallStartRequested(
        otherUserId: 'user_david',
        otherUserName: 'David Warner',
        type: 'audio',
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<CallState>((s) => s.isRinging)),
      );

      // Call accepted
      bloc.add(const CallAccepted());
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<CallState>((s) => s.isOngoing)),
      );

      // Call ticks to 125 seconds (02:05)
      bloc.add(const CallTimerTicked(125));
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<CallState>((s) => s.durationSeconds == 125)),
      );

      // Call ended
      bloc.add(const CallEndRequested());
      await expectLater(
        bloc.stream,
        emitsThrough(predicate<CallState>((s) => s.isEnded)),
      );

      // Verify WebRTC ended and history recorded
      expect(mockCallsService.callEnded, isTrue);
      expect(mockHistoryService.recordedCalls.length, 1);

      final entry = mockHistoryService.recordedCalls.first;
      final callerCall = entry['callerCall'] as CallModel;
      final receiverCall = entry['receiverCall'] as CallModel;

      expect(callerCall.status, 'outgoing');
      expect(callerCall.duration, 125);
      expect(callerCall.otherUserId, 'user_david');
      expect(callerCall.otherUserName, 'David Warner');

      expect(receiverCall.status, 'incoming');
      expect(receiverCall.duration, 125);

      await bloc.close();
    });

    test('CallStatusUpdated event automatically accepts call on "ongoing"', () async {
      final bloc = CallBloc(
        callsService: mockCallsService,
        signalingService: mockSignalingService,
        historyService: mockHistoryService,
        sessionService: mockSessionService,
      );

      bloc.add(const CallStartRequested(
        otherUserId: 'user_eve',
        otherUserName: 'Eve',
      ));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<CallState>((s) => s.isRinging)),
      );

      // Remote signals 'ongoing'
      bloc.add(const CallStatusUpdated('ongoing'));

      await expectLater(
        bloc.stream,
        emitsThrough(predicate<CallState>((s) => s.isOngoing)),
      );

      await bloc.close();
    });
  });
}
