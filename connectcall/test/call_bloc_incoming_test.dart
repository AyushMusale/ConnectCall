import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectcall/models/call_model.dart';
import 'package:connectcall/screens/call/bloc/call_bloc.dart';
import 'package:connectcall/services/calls.service.dart';
import 'package:connectcall/services/firebase/history.service.dart';
import 'package:connectcall/services/firebase/session.service.dart';
import 'package:connectcall/services/firebase/signaling.service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCallDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  FakeCallDocumentSnapshot(this._id, this._data);
  final String _id;
  final Map<String, dynamic> _data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSignalingService extends SignalingService {
  String? lastUpdatedStatus;
  String? lastUpdatedCallId;
  void Function(DocumentSnapshot<Map<String, dynamic>> callDoc)? onIncomingCallCallback;

  @override
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    lastUpdatedCallId = callId;
    lastUpdatedStatus = status;
  }

  @override
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      listenForIncomingCalls({
    required void Function(DocumentSnapshot<Map<String, dynamic>> callDoc)
        onIncomingCall,
    void Function(Object error)? onError,
  }) {
    onIncomingCallCallback = onIncomingCall;
    return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty().listen((_) {});
  }

  @override
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> listenToCall({
    required String callId,
    dynamic onAnswer,
    dynamic onOffer,
    void Function(String status)? onStatusChanged,
    dynamic onData,
    dynamic onError,
  }) {
    return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty().listen((_) {});
  }
}

class MockCallsService extends CallsService {
  bool answerCallInvoked = false;
  bool rejectCallInvoked = false;

  @override
  Future<void> answerCall(
    String callId, {
    dynamic offer,
    String type = 'audio',
    bool isVideo = false,
    dynamic onRemoteStream,
    void Function(String status)? onCallStatusChanged,
  }) async {
    answerCallInvoked = true;
  }

  @override
  Future<void> rejectCall(String callId) async {
    rejectCallInvoked = true;
  }
}

class MockHistoryService extends HistoryService {
  bool recordCallInvoked = false;

  @override
  Future<void> recordCallForBothUsers({
    required CallModel callerCall,
    required CallModel receiverCall,
    required String callerId,
    required String receiverId,
  }) async {
    recordCallInvoked = true;
  }
}

void main() {
  group('CallBloc Incoming Call Lifecycle Tests', () {
    late MockSignalingService mockSignaling;
    late MockCallsService mockCalls;
    late MockHistoryService mockHistory;
    late CallBloc callBloc;

    setUp(() {
      mockSignaling = MockSignalingService();
      mockCalls = MockCallsService();
      mockHistory = MockHistoryService();
      callBloc = CallBloc(
        signalingService: mockSignaling,
        callsService: mockCalls,
        historyService: mockHistory,
        sessionService: SessionService(),
        timeoutDuration: const Duration(seconds: 30),
      );
    });

    tearDown(() async {
      await callBloc.close();
    });

    test('CallIncomingReceived sets incoming state with caller details', () async {
      callBloc.add(const CallIncomingReceived(
        callId: 'call_test_1',
        callerId: 'user_caller',
        callerName: 'Aditi Sharma',
        callerAvatar: 'https://example.com/aditi.jpg',
        type: 'audio',
      ));

      await expectLater(
        callBloc.stream,
        emits(
          predicate<CallState>((s) =>
              s.status == CallStateStatus.incoming &&
              s.isIncoming &&
              s.isActive &&
              s.callId == 'call_test_1' &&
              s.otherUserId == 'user_caller' &&
              s.otherUserName == 'Aditi Sharma' &&
              s.otherUserAvatar == 'https://example.com/aditi.jpg' &&
              s.callType == 'audio' &&
              s.ringRemainingSeconds == 30),
        ),
      );
    });

    test('CallPickUpRequested transitions incoming to ongoing and answers call', () async {
      callBloc.add(const CallIncomingReceived(
        callId: 'call_test_2',
        callerId: 'user_caller',
        callerName: 'Aditi Sharma',
        type: 'audio',
      ));

      await expectLater(
        callBloc.stream,
        emits(predicate<CallState>((s) => s.isIncoming)),
      );

      callBloc.add(const CallPickUpRequested());

      await expectLater(
        callBloc.stream,
        emits(
          predicate<CallState>((s) =>
              s.status == CallStateStatus.ongoing &&
              s.isOngoing &&
              s.durationSeconds == 0),
        ),
      );

      expect(mockCalls.answerCallInvoked, isTrue);
    });

    test('CallRejectRequested transitions incoming to rejected and updates services', () async {
      callBloc.add(const CallIncomingReceived(
        callId: 'call_test_3',
        callerId: 'user_caller',
        callerName: 'Aditi Sharma',
        type: 'audio',
      ));

      await expectLater(
        callBloc.stream,
        emits(predicate<CallState>((s) => s.isIncoming)),
      );

      callBloc.add(const CallRejectRequested());

      await expectLater(
        callBloc.stream,
        emits(
          predicate<CallState>((s) =>
              s.status == CallStateStatus.rejected &&
              s.isRejected &&
              s.ringRemainingSeconds == 0),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(mockSignaling.lastUpdatedStatus, equals('rejected'));
      expect(mockCalls.rejectCallInvoked, isTrue);
      expect(mockHistory.recordCallInvoked, isTrue);
    });

    test('Remote status update to missed while incoming marks call as missed', () async {
      callBloc.add(const CallIncomingReceived(
        callId: 'call_test_4',
        callerId: 'user_caller',
        callerName: 'Aditi Sharma',
      ));

      await expectLater(
        callBloc.stream,
        emits(predicate<CallState>((s) => s.isIncoming)),
      );

      callBloc.add(const CallStatusUpdated('missed'));

      await expectLater(
        callBloc.stream,
        emits(
          predicate<CallState>((s) =>
              s.status == CallStateStatus.missed && s.isMissed),
        ),
      );
    });

    test('Remote status update to ended while incoming triggers ended', () async {
      callBloc.add(const CallIncomingReceived(
        callId: 'call_test_5',
        callerId: 'user_caller',
        callerName: 'Aditi Sharma',
      ));

      await expectLater(
        callBloc.stream,
        emits(predicate<CallState>((s) => s.isIncoming)),
      );

      callBloc.add(const CallStatusUpdated('ended'));

      await expectLater(
        callBloc.stream,
        emits(
          predicate<CallState>((s) =>
              s.status == CallStateStatus.ended && s.isEnded),
        ),
      );
    });

    test('Continuous incoming call listener in CallBloc super triggers CallIncomingReceived', () async {
      await pumpEventQueue();
      expect(mockSignaling.onIncomingCallCallback, isNotNull);

      mockSignaling.onIncomingCallCallback!(
        FakeCallDocumentSnapshot('call_auto_1', {
          'callerId': 'user_auto_caller',
          'callerName': 'Rohan Mehta',
          'callerAvatar': 'https://example.com/rohan.jpg',
          'type': 'video',
        }),
      );

      await expectLater(
        callBloc.stream,
        emits(
          predicate<CallState>((s) =>
              s.status == CallStateStatus.incoming &&
              s.isIncoming &&
              s.callId == 'call_auto_1' &&
              s.otherUserId == 'user_auto_caller' &&
              s.otherUserName == 'Rohan Mehta' &&
              s.otherUserAvatar == 'https://example.com/rohan.jpg' &&
              s.callType == 'video'),
        ),
      );
    });

    test('CallsService listenForIncomingCalls attaches subscription and forwards call', () async {
      final callsService = CallsService(signalingService: mockSignaling);
      Map<String, dynamic>? capturedData;
      String? capturedCallId;

      final sub = callsService.listenForIncomingCalls(
        onIncomingCall: (data, callId) {
          capturedData = data;
          capturedCallId = callId;
        },
      );

      expect(sub, isNotNull);
      expect(callsService.incomingCallsSubscription, equals(sub));

      mockSignaling.onIncomingCallCallback!(
        FakeCallDocumentSnapshot('call_svc_1', {
          'callerId': 'usr_1',
          'type': 'audio',
        }),
      );

      expect(capturedCallId, 'call_svc_1');
      expect(capturedData?['callerId'], 'usr_1');

      await callsService.cancelIncomingCallsListener();
      expect(callsService.incomingCallsSubscription, isNull);
    });
  });
}
