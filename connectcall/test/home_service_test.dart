import 'package:connectcall/injection.dart';
import 'package:connectcall/models/call_model.dart';
import 'package:connectcall/models/history_model.dart';
import 'package:connectcall/services/firebase/home.service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHomeService extends HomeService {
  FakeHomeService({
    this.currentUid = 'user_123',
    Map<String, List<Map<String, dynamic>>>? initialStorage,
  }) : storage = initialStorage ?? {};

  String? currentUid;
  // storage[userId] -> list of call JSON maps
  final Map<String, List<Map<String, dynamic>>> storage;

  @override
  Future<HistoryModel> getCallHistory({String? userId}) async {
    final uid = userId ?? currentUid;
    if (uid == null || uid.isEmpty) {
      return const HistoryModel(history: []);
    }

    final rawCalls = storage[uid] ?? [];
    final calls = rawCalls.map((data) {
      return CallModel.fromJson(data);
    }).toList();

    calls.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return HistoryModel(history: calls);
  }

  @override
  Future<List<CallModel>> getCalls({String? userId}) async {
    final history = await getCallHistory(userId: userId);
    return history.history;
  }

  @override
  Stream<HistoryModel> watchCallHistory({String? userId}) async* {
    yield await getCallHistory(userId: userId);
  }

  @override
  Future<String> addCall(CallModel call, {String? userId}) async {
    final uid = userId ?? currentUid;
    if (uid == null || uid.isEmpty) {
      throw StateError('User is not authenticated.');
    }

    final docId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    final data = {
      'id': docId,
      ...call.toJson(),
    };

    storage.putIfAbsent(uid, () => []).add(data);
    return docId;
  }
}

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  group('HomeService Unit Tests', () {
    test('Returns empty history when user is not authenticated and no userId passed', () async {
      final service = FakeHomeService(currentUid: null);
      final history = await service.getCallHistory();

      expect(history.isEmpty, isTrue);
      expect(history.history, isEmpty);
    });

    test('Retrieves calls from /profile/{currentUserId}/history/ and converts to HistoryModel', () async {
      final sampleCalls = [
        {
          'id': 'c1',
          'otherUserId': 'u_aditi',
          'otherUserName': 'Aditi Sharma',
          'otherUserAvatar': 'https://example.com/avatar.jpg',
          'type': 'video',
          'createdAt': '2026-09-10T12:00:00.000Z',
          'status': 'incoming',
          'duration': 754,
        },
        {
          'id': 'c2',
          'otherUserId': 'u_rohan',
          'otherUserName': 'Rohan Mehta',
          'otherUserAvatar': null,
          'type': 'audio',
          'createdAt': '2026-09-10T15:00:00.000Z',
          'status': 'missed',
          'duration': null,
        },
      ];

      final service = FakeHomeService(
        currentUid: 'user_123',
        initialStorage: {'user_123': sampleCalls},
      );

      final history = await service.getCallHistory();

      expect(history.length, 2);
      // Newest call should be first (sorted descending by createdAt)
      expect(history.history.first.otherUserName, 'Rohan Mehta');
      expect(history.history.first.isMissed, isTrue);
      expect(history.history.first.id, 'c2');

      expect(history.history.last.otherUserName, 'Aditi Sharma');
      expect(history.history.last.isVideo, isTrue);
      expect(history.history.last.formattedDuration, '12:34');
      expect(history.history.last.timeSubtitle, 'Incoming · 12:34');
    });

    test('getCalls convenience method returns List<CallModel>', () async {
      final sampleCalls = [
        {
          'id': 'c1',
          'otherUserId': 'u_karan',
          'otherUserName': 'Karan Desai',
          'type': 'audio',
          'createdAt': '2026-09-10T10:00:00.000Z',
          'status': 'outgoing',
          'duration': 180,
        },
      ];

      final service = FakeHomeService(
        currentUid: 'user_123',
        initialStorage: {'user_123': sampleCalls},
      );

      final calls = await service.getCalls();
      expect(calls.length, 1);
      expect(calls.first.otherUserName, 'Karan Desai');
      expect(calls.first.isOutgoing, isTrue);
      expect(calls.first.formattedDuration, '03:00');
    });

    test('watchCallHistory streams updates to HistoryModel', () async {
      final sampleCalls = [
        {
          'id': 'c1',
          'otherUserId': 'u_priya',
          'otherUserName': 'Priya Nair',
          'type': 'video',
          'createdAt': '2026-09-10T11:00:00.000Z',
          'status': 'incoming',
          'duration': 500,
        },
      ];

      final service = FakeHomeService(
        currentUid: 'user_123',
        initialStorage: {'user_123': sampleCalls},
      );

      final stream = service.watchCallHistory();
      final firstEmission = await stream.first;

      expect(firstEmission.length, 1);
      expect(firstEmission.history.first.otherUserName, 'Priya Nair');
    });

    test('addCall saves call and retrieves it with getCallHistory', () async {
      final service = FakeHomeService(currentUid: 'user_456');

      final newCall = CallModel(
        otherUserId: 'u_neha',
        otherUserName: 'Neha Gupta',
        type: 'audio',
        createdAt: DateTime.now(),
        status: 'outgoing',
        duration: 95,
      );

      final docId = await service.addCall(newCall);
      expect(docId, isNotEmpty);

      final history = await service.getCallHistory();
      expect(history.length, 1);
      expect(history.history.first.otherUserName, 'Neha Gupta');
      expect(history.history.first.duration, 95);
    });

    test('HomeService is registered in GetIt container', () {
      expect(getIt.isRegistered<HomeService>(), isTrue);
      expect(homeService, isNotNull);
    });
  });
}
