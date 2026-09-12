import 'package:connectcall/injection.dart';
import 'package:connectcall/models/call_model.dart';
import 'package:connectcall/models/history_model.dart';
import 'package:connectcall/screens/home/bloc/history_bloc.dart';
import 'package:connectcall/screens/home/home_page.dart';
import 'package:connectcall/screens/home/widgets/call_log_item.dart';
import 'package:connectcall/services/firebase/history.service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSuccessHistoryService extends HistoryService {
  MockSuccessHistoryService(this.calls);

  final List<CallModel> calls;

  @override
  Future<HistoryModel> getCallHistory({String? userId}) async {
    return HistoryModel(history: calls);
  }

  @override
  Stream<HistoryModel> watchCallHistory({String? userId}) async* {
    yield HistoryModel(history: calls);
  }

  @override
  Future<String> addCall(CallModel call, {String? userId}) async {
    calls.insert(0, call);
    return 'call_new_id';
  }
}

class MockFailureHistoryService extends HistoryService {
  @override
  Future<HistoryModel> getCallHistory({String? userId}) async {
    throw Exception('Firestore network timeout');
  }

  @override
  Stream<HistoryModel> watchCallHistory({String? userId}) async* {
    throw Exception('Firestore stream error');
  }
}

void main() {
  setUp(() {
    configureDependencies();
  });

  group('HistoryBloc Unit Tests', () {
    test('Emits [loading, success] with mapped CallModel on fetch success', () async {
      final mockCalls = [
        CallModel(
          id: 'c1',
          otherUserId: 'usr_1',
          otherUserName: 'Aditi Sharma',
          otherUserAvatar: 'https://example.com/aditi.png',
          type: 'audio',
          createdAt: DateTime.now(),
          status: 'outgoing',
          duration: 120,
        ),
        CallModel(
          id: 'c2',
          otherUserId: 'usr_2',
          otherUserName: 'Rohan Mehta',
          otherUserAvatar: null,
          type: 'audio',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          status: 'missed',
          duration: null,
        ),
      ];

      final bloc = HistoryBloc(
        historyService: MockSuccessHistoryService(mockCalls),
      );

      bloc.add(const HistoryFetchRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<HistoryState>((s) => s.isLoading),
          predicate<HistoryState>((s) {
            if (!s.isSuccess || s.calls.length != 2) return false;
            final first = s.calls[0];
            final second = s.calls[1];
            return first.otherUserName == 'Aditi Sharma' &&
                first.isOutgoing &&
                second.otherUserName == 'Rohan Mehta' &&
                second.isMissed;
          }),
        ]),
      );

      await bloc.close();
    });

    test('Emits [loading, failure] on fetch error', () async {
      final mockService = MockFailureHistoryService();
      final bloc = HistoryBloc(historyService: mockService);

      bloc.add(const HistoryFetchRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<HistoryState>((s) => s.isLoading),
          predicate<HistoryState>((s) =>
              s.isFailure &&
              (s.errorMessage?.contains('Firestore network timeout') ?? false)),
        ]),
      );

      await bloc.close();
    });

    test('Filters calls by chip filter (Missed, Incoming, Outgoing, All)', () {
      final mockCalls = [
        CallModel(
          otherUserId: 'u1',
          otherUserName: 'Rohan Mehta',
          type: 'audio',
          createdAt: DateTime.now(),
          status: 'missed',
        ),
        CallModel(
          otherUserId: 'u2',
          otherUserName: 'Priya Nair',
          type: 'video',
          createdAt: DateTime.now(),
          status: 'incoming',
          duration: 300,
        ),
        CallModel(
          otherUserId: 'u3',
          otherUserName: 'Aditi Sharma',
          type: 'audio',
          createdAt: DateTime.now(),
          status: 'outgoing',
          duration: 450,
        ),
      ];

      final state = HistoryState(
        status: HistoryStatus.success,
        history: HistoryModel(history: mockCalls),
      );

      // Default 'All'
      expect(state.filteredCalls.length, 3);

      // 'Missed'
      final missedState = state.copyWith(selectedFilter: 'Missed');
      expect(missedState.filteredCalls.length, 1);
      expect(missedState.filteredCalls.first.otherUserName, 'Rohan Mehta');

      // 'Incoming'
      final incomingState = state.copyWith(selectedFilter: 'Incoming');
      expect(incomingState.filteredCalls.length, 1);
      expect(incomingState.filteredCalls.first.otherUserName, 'Priya Nair');

      // 'Outgoing'
      final outgoingState = state.copyWith(selectedFilter: 'Outgoing');
      expect(outgoingState.filteredCalls.length, 1);
      expect(outgoingState.filteredCalls.first.otherUserName, 'Aditi Sharma');
    });

    test('Filters calls by search query', () {
      final mockCalls = [
        CallModel(
          otherUserId: 'u1',
          otherUserName: 'Aditi Sharma',
          type: 'audio',
          createdAt: DateTime.now(),
          status: 'outgoing',
        ),
        CallModel(
          otherUserId: 'u2',
          otherUserName: 'Rohan Mehta',
          type: 'audio',
          createdAt: DateTime.now(),
          status: 'missed',
        ),
      ];

      final state = HistoryState(
        status: HistoryStatus.success,
        history: HistoryModel(history: mockCalls),
        searchQuery: 'rohan',
      );

      expect(state.filteredCalls.length, 1);
      expect(state.filteredCalls.first.otherUserName, 'Rohan Mehta');
    });

    test('HistoryCallAdded appends new call to history', () async {
      final mockService = MockSuccessHistoryService([]);
      final bloc = HistoryBloc(historyService: mockService);

      final newCall = CallModel(
        otherUserId: 'u_neha',
        otherUserName: 'Neha Gupta',
        type: 'audio',
        createdAt: DateTime.now(),
        status: 'outgoing',
        duration: 60,
      );

      bloc.add(HistoryCallAdded(newCall));

      await expectLater(
        bloc.stream,
        emits(
          predicate<HistoryState>((s) =>
              s.isSuccess &&
              s.calls.length == 1 &&
              s.calls.first.otherUserName == 'Neha Gupta'),
        ),
      );

      await bloc.close();
    });
  });

  group('HomePage UI State Rendering Tests with HistoryBloc', () {
    testWidgets('While loading shows phone icon with skeleton animation', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = HistoryBloc(
        historyService: MockSuccessHistoryService([]),
      );
      bloc.emit(const HistoryState(status: HistoryStatus.loading));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<HistoryBloc>.value(
            value: bloc,
            child: const HomePage(),
          ),
        ),
      );

      expect(find.byType(HistoryLoadingSkeleton), findsOneWidget);
      expect(find.byIcon(Icons.phone_rounded), findsWidgets);
      expect(find.text('Loading call history...'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      bloc.close();
    });

    testWidgets('If failure shows grey cross with failed text and retry button', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = HistoryBloc(
        historyService: MockSuccessHistoryService([]),
      );
      bloc.emit(const HistoryState(
        status: HistoryStatus.failure,
        errorMessage: 'Firestore network failure',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<HistoryBloc>.value(
            value: bloc,
            child: const HomePage(),
          ),
        ),
      );

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      final crossIcon = tester.widget<Icon>(find.byIcon(Icons.close_rounded));
      expect(crossIcon.color, const Color(0xFF9CA3AF));

      expect(find.text('Failed to load call history'), findsOneWidget);
      expect(find.text('Firestore network failure'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      bloc.close();
    });

    testWidgets('If success and list is empty shows no call history', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = HistoryBloc(
        historyService: MockSuccessHistoryService([]),
      );
      bloc.emit(const HistoryState(
        status: HistoryStatus.success,
        history: HistoryModel(history: []),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<HistoryBloc>.value(
            value: bloc,
            child: const HomePage(),
          ),
        ),
      );

      expect(find.text('No call history'), findsOneWidget);
      expect(find.text('Calls you make or receive will appear here.'),
          findsOneWidget);
      expect(find.byType(CallLogItem), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      bloc.close();
    });

    testWidgets('If success displays dynamic call log items', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = HistoryBloc(
        historyService: MockSuccessHistoryService([]),
      );
      bloc.emit(HistoryState(
        status: HistoryStatus.success,
        history: HistoryModel(
          history: [
            CallModel(
              otherUserId: 'u1',
              otherUserName: 'Aditi Sharma',
              type: 'audio',
              createdAt: DateTime.now(),
              status: 'outgoing',
              duration: 754,
            ),
            CallModel(
              otherUserId: 'u2',
              otherUserName: 'Rohan Mehta',
              type: 'audio',
              createdAt: DateTime.now(),
              status: 'missed',
            ),
          ],
        ),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<HistoryBloc>.value(
            value: bloc,
            child: const HomePage(),
          ),
        ),
      );

      expect(find.byType(CallLogItem), findsNWidgets(2));
      expect(find.text('Aditi Sharma'), findsOneWidget);
      expect(find.text('Rohan Mehta'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      bloc.close();
    });
  });
}
