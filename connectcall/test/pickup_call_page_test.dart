import 'package:connectcall/injection.dart';
import 'package:connectcall/screens/call/bloc/call_bloc.dart';
import 'package:connectcall/screens/call/pickup_call_page.dart';
import 'package:connectcall/services/calls.service.dart';
import 'package:connectcall/services/firebase/history.service.dart';
import 'package:connectcall/services/firebase/session.service.dart';
import 'package:connectcall/services/firebase/signaling.service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTestCallsService extends CallsService {
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

class MockTestSignalingService extends SignalingService {
  @override
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {}
}

class MockTestHistoryService extends HistoryService {}

class MockTestSessionService extends SessionService {
  @override
  bool hasActiveSession() => true;
}

void main() {
  setUp(() {
    configureDependencies();
  });

  group('PickupCallPage Visual & UI Tests (pickup-call-page.png)', () {
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

    testWidgets('Renders all visual elements matching design mock', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      testBloc.emit(const CallState(
        status: CallStateStatus.incoming,
        callId: 'call_123',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: PickupCallPage(
            callBloc: testBloc,
            contactName: 'Aditi Sharma',
            avatarUrl: null,
            callType: 'audio',
          ),
        ),
      );
      await tester.pump();

      // 1. Top Brand Header
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

      // 2. Caller Info
      expect(find.text('Aditi Sharma'), findsOneWidget);
      expect(find.text('Incoming call...'), findsOneWidget);

      // 3. Action Buttons
      expect(find.byKey(const Key('pickup_end_button')), findsOneWidget);
      expect(find.byKey(const Key('pickup_accept_button')), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.text('Pick Up'), findsOneWidget);

      // 4. Icons
      expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
      expect(find.byIcon(Icons.call_rounded), findsOneWidget);
    });

    testWidgets('Tapping End triggers onEnd callback', (
      WidgetTester tester,
    ) async {
      bool endTapped = false;

      testBloc.emit(const CallState(
        status: CallStateStatus.incoming,
        callId: 'call_123',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: PickupCallPage(
            callBloc: testBloc,
            contactName: 'Aditi Sharma',
            avatarUrl: null,
            onEnd: () {
              endTapped = true;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('pickup_end_button')));
      await tester.pump();

      expect(endTapped, isTrue);
    });

    testWidgets('Tapping Pick Up triggers onPickUp callback', (
      WidgetTester tester,
    ) async {
      bool pickUpTapped = false;

      testBloc.emit(const CallState(
        status: CallStateStatus.incoming,
        callId: 'call_123',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: PickupCallPage(
            callBloc: testBloc,
            contactName: 'Aditi Sharma',
            avatarUrl: null,
            onPickUp: () {
              pickUpTapped = true;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('pickup_accept_button')));
      await tester.pump();

      expect(pickUpTapped, isTrue);
    });

    testWidgets('Renders Incoming Video Call badge above avatar for video calls', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      testBloc.emit(const CallState(
        status: CallStateStatus.incoming,
        callId: 'call_video_1',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
        callType: 'video',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: PickupCallPage(
            callBloc: testBloc,
            contactName: 'Aditi Sharma',
            callType: 'video',
          ),
        ),
      );
      await tester.pump();

      // 1. Video call badge exists
      final badgeFinder = find.byKey(const Key('pickup_video_call_badge'));
      expect(badgeFinder, findsOneWidget);
      expect(find.text('Incoming Video Call'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
      expect(find.text('30s'), findsOneWidget);

      // 2. Video call badge is positioned above the avatar
      final badgePos = tester.getTopLeft(badgeFinder);
      final avatarPos = tester.getTopLeft(find.byType(CircleAvatar));
      expect(badgePos.dy, lessThan(avatarPos.dy));
    });

    testWidgets('Does not render Video Call badge for audio calls', (
      WidgetTester tester,
    ) async {
      testBloc.emit(const CallState(
        status: CallStateStatus.incoming,
        callId: 'call_audio_1',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
        callType: 'audio',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: PickupCallPage(
            callBloc: testBloc,
            contactName: 'Aditi Sharma',
            callType: 'audio',
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('pickup_video_call_badge')), findsNothing);
      expect(find.text('Incoming Video Call'), findsNothing);
      expect(find.text('Incoming call...'), findsOneWidget);
    });

    testWidgets('Stays on screen and counts down without dismissing when call ended occurs', (
      WidgetTester tester,
    ) async {
      testBloc.emit(const CallState(
        status: CallStateStatus.incoming,
        callId: 'call_countdown_1',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
        callType: 'video',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: PickupCallPage(
            callBloc: testBloc,
            contactName: 'Aditi Sharma',
            callType: 'video',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('30s'), findsOneWidget);

      // Simulate remote side ending / failing
      testBloc.emit(const CallState(
        status: CallStateStatus.ended,
        callId: 'call_countdown_1',
      ));
      await tester.pump(const Duration(seconds: 1));

      // Page must NOT dismiss; it remains active for user to choose
      expect(find.byKey(const Key('pickup_video_call_badge')), findsOneWidget);
      expect(find.text('29s'), findsOneWidget);
      expect(find.byKey(const Key('pickup_end_button')), findsOneWidget);
      expect(find.byKey(const Key('pickup_accept_button')), findsOneWidget);

      // Advance 10 more seconds
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('19s'), findsOneWidget);
    });

    testWidgets('30-second timeout automatically triggers timeout missed', (
      WidgetTester tester,
    ) async {
      testBloc.emit(const CallState(
        status: CallStateStatus.incoming,
        callId: 'call_timeout_1',
        otherUserId: 'cnt-1',
        otherUserName: 'Aditi Sharma',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: PickupCallPage(
            callBloc: testBloc,
            contactName: 'Aditi Sharma',
            timeoutDuration: const Duration(seconds: 3),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('pickup_end_button')), findsOneWidget);

      // Advance 3 seconds to expire timeout
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(testBloc.state.isMissed, isTrue);
    });

    testWidgets('Once receiver accepts the video call shows same UI as caller with localstream on bottom right and options', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      testBloc.emit(const CallState(
        status: CallStateStatus.incoming,
        callId: 'call_video_accept_123',
        otherUserId: 'caller-1',
        otherUserName: 'Aditi Sharma',
        callType: 'video',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: PickupCallPage(
            callBloc: testBloc,
            callId: 'call_video_accept_123',
            otherUserId: 'caller-1',
            contactName: 'Aditi Sharma',
            avatarUrl: null,
            callType: 'video',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pick Up'), findsOneWidget);

      // Receiver accepts the video call
      await tester.tap(find.byKey(const Key('pickup_accept_button')));
      await tester.pump();

      // Verify that after accepting, receiver sees the same ongoing UI as caller:
      // 1. Receiver's local stream preview in bottom-right corner with 'You'
      expect(find.byKey(const Key('local_video_stream')), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // 2. Caller full-screen video stream container
      expect(find.byKey(const Key('remote_video_stream')), findsOneWidget);

      // 3. Caller name and duration
      expect(find.text('Aditi Sharma'), findsWidgets);
      expect(find.text('00:00'), findsOneWidget);

      // 4. Options dock: Mute, Flip, Cam Off, End
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Flip'), findsOneWidget);
      expect(find.text('Cam Off'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
    });
  });

  group('PickupCallPage LayoutBuilder & Responsiveness Tests', () {
    final devices = <String, Size>{
      'Small Budget Phone (320x568)': const Size(320, 568),
      'iPhone SE / Compact (375x667)': const Size(375, 667),
      'Standard Android (360x780)': const Size(360, 780),
      'iPhone 14/15/16 (390x844)': const Size(390, 844),
      'Large Pro Max Phone (430x932)': const Size(430, 932),
      'Foldable Open / Tablet (768x1024)': const Size(768, 1024),
      'Desktop / Laptop (1280x800)': const Size(1280, 800),
    };

    for (final entry in devices.entries) {
      testWidgets('Renders without overflow on ${entry.key} for video call', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final bloc = CallBloc(
          callsService: MockTestCallsService(),
          signalingService: MockTestSignalingService(),
          historyService: MockTestHistoryService(),
          sessionService: MockTestSessionService(),
        );
        bloc.emit(const CallState(
          status: CallStateStatus.incoming,
          callId: 'call_123',
          otherUserId: 'cnt-1',
          otherUserName: 'Aditi Sharma',
          callType: 'video',
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: PickupCallPage(
              callBloc: bloc,
              contactName: 'Aditi Sharma',
              avatarUrl: null,
              callType: 'video',
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('pickup_video_call_badge')), findsOneWidget);
        expect(find.text('Incoming Video Call'), findsOneWidget);
        expect(find.text('Aditi Sharma'), findsOneWidget);
        expect(find.text('Incoming call...'), findsOneWidget);
        expect(find.text('End'), findsOneWidget);
        expect(find.text('Pick Up'), findsOneWidget);

        bloc.close();
      });
    }
  });
}
