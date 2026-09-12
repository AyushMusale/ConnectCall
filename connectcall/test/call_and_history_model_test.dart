import 'package:flutter_test/flutter_test.dart';
import 'package:connectcall/models/call_model.dart';
import 'package:connectcall/models/history_model.dart';
import 'package:connectcall/screens/home/models/call_log_model.dart';

void main() {
  group('CallModel tests', () {
    test('fromJson and toJson work correctly with full data', () {
      final json = {
        'callerId': 'usr_123',
        'otherUserId': 'usr_456',
        'otherUserName': 'Aditi Sharma',
        'otherUserAvatar': 'https://example.com/avatar.jpg',
        'type': 'video',
        'createdAt': '2026-09-10T15:30:00.000Z',
        'status': 'incoming',
        'duration': 754,
      };

      final call = CallModel.fromJson(json);

      expect(call.callerId, 'usr_123');
      expect(call.otherUserId, 'usr_456');
      expect(call.otherUserName, 'Aditi Sharma');
      expect(call.otherUserAvatar, 'https://example.com/avatar.jpg');
      expect(call.type, 'video');
      expect(call.isVideo, isTrue);
      expect(call.isAudio, isFalse);
      expect(call.status, 'incoming');
      expect(call.isIncoming, isTrue);
      expect(call.isOutgoing, isFalse);
      expect(call.isMissed, isFalse);
      expect(call.duration, 754);
      expect(call.formattedDuration, '12:34');
      expect(call.timeSubtitle, 'Incoming · 12:34');

      final serialized = call.toJson();
      expect(serialized['callerId'], 'usr_123');
      expect(serialized['otherUserId'], 'usr_456');
      expect(serialized['otherUserName'], 'Aditi Sharma');
      expect(serialized['otherUserAvatar'], 'https://example.com/avatar.jpg');
      expect(serialized['type'], 'video');
      expect(serialized['status'], 'incoming');
      expect(serialized['duration'], 754);
      expect(serialized['createdAt'], isA<String>());
    });

    test('fromJson handles missed call and null duration/avatar', () {
      final json = {
        'otherUserId': 'usr_789',
        'otherUserName': 'Rohan Mehta',
        'otherUserAvatar': null,
        'type': 'audio',
        'createdAt': '2026-09-10T12:00:00.000Z',
        'status': 'missed',
        'duration': null,
      };

      final call = CallModel.fromJson(json);

      expect(call.otherUserId, 'usr_789');
      expect(call.otherUserName, 'Rohan Mehta');
      expect(call.otherUserAvatar, isNull);
      expect(call.isAudio, isTrue);
      expect(call.isVideo, isFalse);
      expect(call.isMissed, isTrue);
      expect(call.duration, isNull);
      expect(call.formattedDuration, '00:00');
      expect(call.timeSubtitle, 'Missed call');
    });

    test('fromJson handles string duration parsing mm:ss', () {
      final json = {
        'otherUserId': 'usr_101',
        'otherUserName': 'Karan Desai',
        'type': 'audio',
        'createdAt': '2026-09-10T12:00:00.000Z',
        'status': 'outgoing',
        'duration': '05:27',
      };

      final call = CallModel.fromJson(json);
      expect(call.duration, 327);
      expect(call.formattedDuration, '05:27');
      expect(call.timeSubtitle, 'Outgoing · 05:27');
    });

    test('copyWith works correctly', () {
      final call = CallModel(
        otherUserId: '1',
        otherUserName: 'Alice',
        type: 'audio',
        createdAt: DateTime(2026, 9, 10, 10, 0),
        status: 'incoming',
      );

      final updated = call.copyWith(otherUserName: 'Alice Smith', type: 'video', isOnline: true);
      expect(updated.otherUserName, 'Alice Smith');
      expect(updated.type, 'video');
      expect(updated.otherUserId, '1');
      expect(updated.isOnline, isTrue);
    });

    test('CallModel and CallLogModel support isOnline flag', () {
      final call = CallModel(
        otherUserId: 'u1',
        otherUserName: 'Aditi',
        type: 'audio',
        createdAt: DateTime(2026, 9, 10),
        status: 'incoming',
        isOnline: true,
      );
      expect(call.isOnline, isTrue);

      final json = call.toJson();
      expect(json['isOnline'], isTrue);

      final fromJson = CallModel.fromJson(json);
      expect(fromJson.isOnline, isTrue);

      // Verify CallLogModel extraction
      final log = CallLogModel.fromCallModel(fromJson);
      expect(log.isOnline, isTrue);

      final updatedLog = log.copyWith(isOnline: false);
      expect(updatedLog.isOnline, isFalse);
    });
  });

  group('HistoryModel tests', () {
    test('fromJson parses history list correctly', () {
      final json = {
        'history': [
          {
            'otherUserId': 'usr_1',
            'otherUserName': 'Aditi Sharma',
            'type': 'video',
            'createdAt': '2026-09-10T12:00:00.000Z',
            'status': 'incoming',
            'duration': 120,
          },
          {
            'otherUserId': 'usr_2',
            'otherUserName': 'Rohan Mehta',
            'type': 'audio',
            'createdAt': '2026-09-10T11:00:00.000Z',
            'status': 'missed',
            'duration': null,
          },
          {
            'otherUserId': 'usr_3',
            'otherUserName': 'Priya Nair',
            'type': 'audio',
            'createdAt': '2026-09-10T10:00:00.000Z',
            'status': 'outgoing',
            'duration': 60,
          },
        ],
      };

      final historyModel = HistoryModel.fromJson(json);

      expect(historyModel.history.length, 3);
      expect(historyModel.isNotEmpty, isTrue);
      expect(historyModel.length, 3);

      expect(historyModel.incomingCalls.length, 1);
      expect(historyModel.incomingCalls.first.otherUserName, 'Aditi Sharma');

      expect(historyModel.missedCalls.length, 1);
      expect(historyModel.missedCalls.first.otherUserName, 'Rohan Mehta');

      expect(historyModel.outgoingCalls.length, 1);
      expect(historyModel.outgoingCalls.first.otherUserName, 'Priya Nair');
    });

    test('fromList parses a raw list of call items', () {
      final list = [
        {
          'otherUserId': 'usr_1',
          'otherUserName': 'Aditi Sharma',
          'type': 'audio',
          'createdAt': '2026-09-10T12:00:00.000Z',
          'status': 'incoming',
        },
      ];

      final historyModel = HistoryModel.fromList(list);
      expect(historyModel.history.length, 1);
      expect(historyModel.history.first.otherUserId, 'usr_1');
    });

    test('fromJson handles null or empty history', () {
      final historyModel = HistoryModel.fromJson({});
      expect(historyModel.isEmpty, isTrue);
      expect(historyModel.history, isEmpty);
    });
  });
}
