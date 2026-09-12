import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectcall/injection.dart';
import 'package:connectcall/screens/call/bloc/call_bloc.dart';
import 'package:connectcall/services/calls.service.dart';
import 'package:connectcall/services/firebase/history.service.dart';
import 'package:connectcall/services/firebase/session.service.dart';
import 'package:connectcall/services/firebase/signaling.service.dart';
import 'package:connectcall/services/webRTC.service.dart';
import 'package:connectcall/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

class MockSignalingServiceForHeader extends SignalingService {
  void Function(DocumentSnapshot<Map<String, dynamic>>)? incomingCallCallback;
  void Function(String)? statusChangedCallback;

  @override
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listenForIncomingCalls({
    required void Function(DocumentSnapshot<Map<String, dynamic>> callDoc) onIncomingCall,
    void Function(Object error)? onError,
  }) {
    incomingCallCallback = onIncomingCall;
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
    statusChangedCallback = onStatusChanged;
    return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty().listen(null);
  }
}

class MockCallsServiceForHeader extends CallsService {
  MockCallsServiceForHeader()
      : super(
          webRTCService: getIt<WebRTCService>(),
          signalingService: getIt<SignalingService>(),
        );

  @override
  StreamSubscription<dynamic>? listenForIncomingCalls({
    required void Function(Map<String, dynamic> data, String callId) onIncomingCall,
    void Function(Object error)? onError,
  }) {
    return const Stream<dynamic>.empty().listen(null);
  }
}

class FakeCallDoc implements DocumentSnapshot<Map<String, dynamic>> {
  FakeCallDoc({required this.id, required this.callData});

  @override
  final String id;
  final Map<String, dynamic> callData;

  @override
  Map<String, dynamic>? data() => callData;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    configureDependencies();
  });

  group('AppHeader Widget Tests', () {
    testWidgets('AppHeader renders brand title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppHeader(maxWidth: 390),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.text('Stay close, no matter the distance'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    testWidgets('AppHeader triggers CallIncomingListenerStarted on CallBloc', (tester) async {
      final mockSignaling = MockSignalingServiceForHeader();
      final callBloc = CallBloc(
        signalingService: mockSignaling,
        callsService: MockCallsServiceForHeader(),
        historyService: HistoryService(),
        sessionService: SessionService(),
      );

      await tester.pumpWidget(
        BlocProvider<CallBloc>.value(
          value: callBloc,
          child: MaterialApp(
            home: Scaffold(
              body: AppHeader(
                maxWidth: 390,
                signalingService: mockSignaling,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(callBloc.state.status, equals(CallStateStatus.initial));
      await callBloc.close();
    });

    testWidgets('AppHeader works gracefully when CallBloc is not provided in context', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppHeader(maxWidth: 390),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppHeader), findsOneWidget);
    });

    testWidgets('Renders pickup call page on ringing and home page once status changes', (tester) async {
      final mockSignaling = MockSignalingServiceForHeader();
      final callBloc = CallBloc(
        signalingService: mockSignaling,
        callsService: MockCallsServiceForHeader(),
        historyService: HistoryService(),
        sessionService: SessionService(),
      );

      final router = GoRouter(
        initialLocation: '/test-header',
        routes: [
          GoRoute(
            path: '/test-header',
            builder: (context, state) => Scaffold(
              body: AppHeader(
                maxWidth: 390,
                signalingService: mockSignaling,
              ),
            ),
          ),
          GoRoute(
            path: '/pickup-call',
            builder: (context, state) => const Scaffold(
              body: Text('PickupCallScreen'),
            ),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(
              body: Text('HomeScreen'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<CallBloc>.value(
          value: callBloc,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppHeader), findsOneWidget);
      expect(mockSignaling.incomingCallCallback, isNotNull);

      // Trigger incoming call with status 'ringing'
      mockSignaling.incomingCallCallback!(
        FakeCallDoc(
          id: 'test_call_99',
          callData: {
            'status': 'ringing',
            'callerId': 'caller_1',
            'callerName': 'Alice Smith',
            'type': 'audio',
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verified: renders pickup call page
      expect(find.text('PickupCallScreen'), findsOneWidget);
      expect(mockSignaling.statusChangedCallback, isNotNull);

      // Verify that 'ended' does not close immediately (page stays open)
      mockSignaling.statusChangedCallback!('ended');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('PickupCallScreen'), findsOneWidget);

      // Once state changes to missed or rejected (or 30s timeout), renders home page
      mockSignaling.statusChangedCallback!('missed');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verified: renders home page
      expect(find.text('HomeScreen'), findsOneWidget);

      await callBloc.close();
    });
  });
}
