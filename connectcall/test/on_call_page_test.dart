import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectcall/models/call_model.dart';
import 'package:go_router/go_router.dart';
import 'package:connectcall/injection.dart';
import 'package:connectcall/screens/call/bloc/call_bloc.dart';
import 'package:connectcall/screens/call/on_call_page.dart';
import 'package:connectcall/screens/call/widgets/make_call_bottom_sheet.dart';
import 'package:connectcall/services/calls.service.dart';
import 'package:connectcall/services/firebase/history.service.dart';
import 'package:connectcall/services/firebase/session.service.dart';
import 'package:connectcall/services/firebase/signaling.service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MockTestCallsService extends CallsService {
  bool endCallCalled = false;

  @override
  Future<String> startCall(
    String otherUserId, {
    String? callerName,
    String? callerAvatar,
    String type = 'audio',
    bool isVideo = false,
    void Function(MediaStream remoteStream)? onRemoteStream,
    void Function(String status)? onCallStatusChanged,
  }) async {
    return 'call_123';
  }

  @override
  Future<void> endCall({String status = 'ended'}) async {
    endCallCalled = true;
  }
}

class MockTestSignalingService extends SignalingService {
  @override
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {}

  @override
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listenForIncomingCalls({
    required void Function(DocumentSnapshot<Map<String, dynamic>> callDoc) onIncomingCall,
    void Function(Object error)? onError,
  }) {
    return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty().listen(null);
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
    return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty().listen(null);
  }
}

class MockTestHistoryService extends HistoryService {
  @override
  Future<void> recordCallForBothUsers({
    required CallModel callerCall,
    required CallModel receiverCall,
    required String callerId,
    required String receiverId,
  }) async {}
}

class MockTestSessionService extends SessionService {
  @override
  bool hasActiveSession() => true;
}

void main() {
  setUp(() {
    configureDependencies();
  });

  group('OnCallPage UI & Elements Matching on_call_page.png', () {
    late CallBloc testBloc;
    late MockTestCallsService mockCallsService;

    setUp(() {
      mockCallsService = MockTestCallsService();
      testBloc = CallBloc(
        callsService: mockCallsService,
        signalingService: MockTestSignalingService(),
        historyService: MockTestHistoryService(),
        sessionService: MockTestSessionService(),
      );
    });

    tearDown(() {
      testBloc.close();
    });

    testWidgets('Renders top brand header, contact avatar with halos, name, in call, duration, mute, and end call button', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pre-seed bloc in ongoing state with 24 seconds to match on_call_page.png
      testBloc.emit(const CallState(
        status: CallStateStatus.ongoing,
        callId: 'call_123',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
        durationSeconds: 24,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnCallPage(
            otherUserId: 'cnt-1',
            contactName: 'Aditi Sharma',
            callBloc: testBloc,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Top Brand Header: Connect-Call and Tagline
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Connect') &&
              widget.text.toPlainText().contains('-Call'),
        ),
        findsOneWidget,
      );
      expect(find.text('Stay close, no matter the distance'), findsOneWidget);

      // 2. Contact Details matching on_call_page.png
      expect(find.text('Aditi Sharma'), findsOneWidget);
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('00:24'), findsOneWidget);

      // 3. Mute Button
      expect(find.text('Mute'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

      // 4. End Call Button
      expect(find.text('End Call'), findsOneWidget);
      expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
    });

    testWidgets('Tapping Mute toggles mute state and label', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool? muteToggledVal;

      testBloc.emit(const CallState(
        status: CallStateStatus.ongoing,
        callId: 'call_123',
        durationSeconds: 10,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnCallPage(
            otherUserId: 'cnt-1',
            contactName: 'Aditi Sharma',
            callBloc: testBloc,
            onMuteToggled: (val) {
              muteToggledVal = val;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mute'), findsOneWidget);

      // Tap mute
      await tester.tap(find.text('Mute'));
      await tester.pumpAndSettle();

      expect(muteToggledVal, isTrue);
      expect(find.text('Unmute'), findsOneWidget);

      // Tap unmute
      await tester.tap(find.text('Unmute'));
      await tester.pumpAndSettle();

      expect(muteToggledVal, isFalse);
      expect(find.text('Mute'), findsOneWidget);
    });

    testWidgets('Tapping End Call triggers call cleanup and onEndCall callback', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool endCallTriggered = false;

      testBloc.emit(const CallState(
        status: CallStateStatus.ongoing,
        callId: 'call_123',
        durationSeconds: 15,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnCallPage(
            otherUserId: 'cnt-1',
            contactName: 'Aditi Sharma',
            callBloc: testBloc,
            onEndCall: () {
              endCallTriggered = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap End Call
      await tester.tap(find.text('End Call'));
      await tester.pumpAndSettle();

      expect(endCallTriggered, isTrue);
    });

    testWidgets('Tapping Audio Call in MakeCallBottomSheet redirects to /on-call', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) => const Scaffold(body: Text('Base Screen')),
          ),
          GoRoute(
            path: '/on-call',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return OnCallPage(
                otherUserId: extra['otherUserId'] as String? ?? 'cnt-1',
                contactName: extra['otherUserName'] as String? ?? 'User',
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Open MakeCallBottomSheet directly
      final context = tester.element(find.byType(Scaffold).first);
      MakeCallBottomSheet.show(
        context,
        contactName: 'Aditi Sharma',
        avatarUrl: null,
      );
      await tester.pumpAndSettle();

      expect(find.text('Audio Call'), findsOneWidget);

      // Tap Audio Call
      await tester.tap(find.text('Audio Call'));
      await tester.pumpAndSettle();

      // Verify redirected to OnCallPage
      expect(find.byType(OnCallPage), findsOneWidget);
      expect(find.text('Aditi Sharma'), findsOneWidget);
      expect(find.text('End Call'), findsOneWidget);
    });

    testWidgets('Tapping Video Call in MakeCallBottomSheet redirects to /on-call', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) => const Scaffold(body: Text('Base Screen')),
          ),
          GoRoute(
            path: '/on-call',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return OnCallPage(
                otherUserId: extra['otherUserId'] as String? ?? 'cnt-1',
                contactName: extra['otherUserName'] as String? ?? 'User',
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Open MakeCallBottomSheet directly
      final context = tester.element(find.byType(Scaffold).first);
      MakeCallBottomSheet.show(
        context,
        contactName: 'Rohan Mehta',
        avatarUrl: null,
      );
      await tester.pumpAndSettle();

      expect(find.text('Video Call'), findsOneWidget);

      // Tap Video Call
      await tester.tap(find.text('Video Call'));
      await tester.pumpAndSettle();

      // Verify redirected to OnCallPage
      expect(find.byType(OnCallPage), findsOneWidget);
      expect(find.text('Rohan Mehta'), findsOneWidget);
      expect(find.text('End Call'), findsOneWidget);
    });

    testWidgets('Ringing state displays Ringing status and 00:30 countdown', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      testBloc.emit(const CallState(
        status: CallStateStatus.ringing,
        callId: 'call_123',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
        ringRemainingSeconds: 30,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnCallPage(
            otherUserId: 'cnt-1',
            contactName: 'Aditi Sharma',
            callBloc: testBloc,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ringing'), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
    });

    testWidgets('Transition from ringing to ongoing updates status to Ongoing and starts forward timer', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      testBloc.emit(const CallState(
        status: CallStateStatus.ringing,
        callId: 'call_123',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
        ringRemainingSeconds: 28,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnCallPage(
            otherUserId: 'cnt-1',
            contactName: 'Aditi Sharma',
            callBloc: testBloc,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ringing'), findsOneWidget);
      expect(find.text('00:28'), findsOneWidget);

      print('BEFORE EMIT: ${testBloc.state}');
      // Status changes to ongoing
      testBloc.emit(testBloc.state.copyWith(
        status: CallStateStatus.ongoing,
        durationSeconds: 0,
      ));
      print('AFTER EMIT: ${testBloc.state}');
      await tester.pump();
      await tester.pump();
      for (final widget in tester.widgetList<Text>(find.byType(Text))) {
        print('FOUND TEXT: "${widget.data}"');
      }

      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);

      // Timer ticks forward
      testBloc.emit(testBloc.state.copyWith(
        status: CallStateStatus.ongoing,
        durationSeconds: 5,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('00:05'), findsOneWidget);
    });

    testWidgets('Ended status displays Call Ended', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      testBloc.emit(const CallState(
        status: CallStateStatus.ended,
        callId: 'call_123',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnCallPage(
            otherUserId: 'cnt-1',
            contactName: 'Aditi Sharma',
            callBloc: testBloc,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Call Ended'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1200));
    });

    testWidgets('Missed status displays Call Missed and 00:00', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      testBloc.emit(const CallState(
        status: CallStateStatus.missed,
        callId: 'call_123',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnCallPage(
            otherUserId: 'cnt-1',
            contactName: 'Aditi Sharma',
            callBloc: testBloc,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Call Missed'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1200));
    });

    testWidgets('Video call ongoing renders remote video, local video in bottom-right corner, and controls', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      testBloc.emit(const CallState(
        status: CallStateStatus.ongoing,
        callId: 'call_video_123',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
        callType: 'video',
        durationSeconds: 15,
      ));

      bool cameraSwitched = false;
      bool cameraToggled = false;
      bool muteToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnCallPage(
            otherUserId: 'cnt-1',
            contactName: 'Aditi Sharma',
            callType: 'video',
            callBloc: testBloc,
            onCameraSwitched: () => cameraSwitched = true,
            onCameraToggled: (val) => cameraToggled = val,
            onMuteToggled: (val) => muteToggled = val,
          ),
        ),
      );
      await tester.pump();

      // Remote video stream container
      expect(find.byKey(const Key('remote_video_stream')), findsOneWidget);

      // Local video stream container in bottom-right corner
      expect(find.byKey(const Key('local_video_stream')), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // Call header
      expect(find.text('Aditi Sharma'), findsWidgets);
      expect(find.text('00:15'), findsOneWidget);

      // Video Controls: Mute, Flip, Cam Off, End
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Flip'), findsOneWidget);
      expect(find.text('Cam Off'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);

      // Tap Flip Camera
      await tester.tap(find.text('Flip'));
      await tester.pump();
      expect(cameraSwitched, isTrue);

      // Tap Turn Off Camera
      await tester.tap(find.text('Cam Off'));
      await tester.pump();
      expect(cameraToggled, isTrue);
      expect(find.text('Cam On'), findsOneWidget);

      // Tap Mute
      await tester.tap(find.text('Mute'));
      await tester.pump();
      expect(muteToggled, isTrue);
      expect(find.text('Unmute'), findsOneWidget);
    });

    testWidgets('Receiver side video call ongoing renders remote video, local video in bottom-right corner, and controls without triggering CallStartRequested', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pre-seed bloc in ongoing state for receiver
      testBloc.emit(const CallState(
        status: CallStateStatus.ongoing,
        callId: 'call_video_incoming_123',
        otherUserId: 'caller-456',
        otherUserName: 'Rahul Verma',
        callType: 'video',
        durationSeconds: 42,
      ));

      bool cameraSwitched = false;
      bool cameraToggled = false;
      bool muteToggled = false;
      bool endCallTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnCallPage(
            otherUserId: 'caller-456',
            contactName: 'Rahul Verma',
            callType: 'video',
            callId: 'call_video_incoming_123',
            isIncoming: true,
            callBloc: testBloc,
            onCameraSwitched: () => cameraSwitched = true,
            onCameraToggled: (val) => cameraToggled = val,
            onMuteToggled: (val) => muteToggled = val,
            onEndCall: () => endCallTapped = true,
          ),
        ),
      );
      await tester.pump();

      // Ensure no new outgoing call was initiated by receiver
      expect(testBloc.state.status, equals(CallStateStatus.ongoing));
      expect(testBloc.state.callId, equals('call_video_incoming_123'));

      // Remote video stream container
      expect(find.byKey(const Key('remote_video_stream')), findsOneWidget);

      // Local video stream preview in bottom-right corner
      expect(find.byKey(const Key('local_video_stream')), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // Top Call header with caller name and duration
      expect(find.text('Rahul Verma'), findsWidgets);
      expect(find.text('00:42'), findsOneWidget);

      // Video Controls: Mute, Flip, Cam Off, End
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Flip'), findsOneWidget);
      expect(find.text('Cam Off'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);

      // Tap Flip Camera
      await tester.tap(find.text('Flip'));
      await tester.pump();
      expect(cameraSwitched, isTrue);

      // Tap Turn Off Camera
      await tester.tap(find.text('Cam Off'));
      await tester.pump();
      expect(cameraToggled, isTrue);
      expect(find.text('Cam On'), findsOneWidget);

      // Tap Mute
      await tester.tap(find.text('Mute'));
      await tester.pump();
      expect(muteToggled, isTrue);
      expect(find.text('Unmute'), findsOneWidget);

      // Tap End Call
      await tester.tap(find.text('End'));
      await tester.pump();
      expect(endCallTapped, isTrue);
    });

    testWidgets('Receiver side video call connecting displays Incoming Video Call badge above avatar and local video preview', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pre-seed bloc in incoming state
      testBloc.emit(const CallState(
        status: CallStateStatus.incoming,
        callId: 'call_video_incoming_456',
        otherUserId: 'caller-789',
        otherUserName: 'Sneha Patel',
        callType: 'video',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnCallPage(
            otherUserId: 'caller-789',
            contactName: 'Sneha Patel',
            callType: 'video',
            callId: 'call_video_incoming_456',
            isIncoming: true,
            callBloc: testBloc,
          ),
        ),
      );
      await tester.pump();

      // Connecting layout renders the video call badge above avatar
      expect(find.byKey(const Key('on_call_video_badge')), findsOneWidget);
      expect(find.text('Incoming Video Call'), findsOneWidget);

      // Caller Name and avatar
      expect(find.text('Sneha Patel'), findsOneWidget);

      // Local video preview in bottom-right corner
      expect(find.byKey(const Key('local_video_stream')), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // Controls dock
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Flip'), findsOneWidget);
      expect(find.text('Cam Off'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
    });
  });
}

