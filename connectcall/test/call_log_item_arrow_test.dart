import 'package:connectcall/models/call_model.dart';
import 'package:connectcall/screens/home/models/call_log_model.dart';
import 'package:connectcall/screens/home/widgets/call_log_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CallLogItem arrow icon direction tests', () {
    const currentUserId = 'user_123';
    const otherUserId = 'user_456';

    testWidgets(
      'currentUserId == callerId shows tilted upper arrow for outgoing call',
      (tester) async {
        final callModel = CallModel(
          callerId: currentUserId,
          otherUserId: otherUserId,
          otherUserName: 'Alice',
          type: 'audio',
          createdAt: DateTime.now(),
          status: 'outgoing',
          duration: 120,
        );
        final callLog = CallLogModel.fromCallModel(callModel);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CallLogItem(
                call: callLog,
                maxWidth: 390,
                currentUserId: currentUserId,
              ),
            ),
          ),
        );

        // Expect tilted upper arrow (Icons.north_east_rounded)
        expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
        expect(find.byIcon(Icons.south_west_rounded), findsNothing);

        final icon = tester.widget<Icon>(find.byIcon(Icons.north_east_rounded));
        expect(icon.color, const Color(0xFFFF6E00));
      },
    );

    testWidgets(
      'currentUserId == callerId shows tilted upper arrow for missed call',
      (tester) async {
        final callModel = CallModel(
          callerId: currentUserId,
          otherUserId: otherUserId,
          otherUserName: 'Bob',
          type: 'audio',
          createdAt: DateTime.now(),
          status: 'missed',
          duration: 0,
        );
        final callLog = CallLogModel.fromCallModel(callModel);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CallLogItem(
                call: callLog,
                maxWidth: 390,
                currentUserId: currentUserId,
              ),
            ),
          ),
        );

        // Expect tilted upper arrow (Icons.north_east_rounded) in red
        expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
        expect(find.byIcon(Icons.south_west_rounded), findsNothing);

        final icon = tester.widget<Icon>(find.byIcon(Icons.north_east_rounded));
        expect(icon.color, const Color(0xFFE53935)); // Red for missed
      },
    );

    testWidgets(
      'currentUserId == callerId shows tilted upper arrow for ended call',
      (tester) async {
        final callModel = CallModel(
          callerId: currentUserId,
          otherUserId: otherUserId,
          otherUserName: 'Charlie',
          type: 'video',
          createdAt: DateTime.now(),
          status: 'ended',
          duration: 250,
        );
        final callLog = CallLogModel.fromCallModel(callModel);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CallLogItem(
                call: callLog,
                maxWidth: 390,
                currentUserId: currentUserId,
              ),
            ),
          ),
        );

        // Expect tilted upper arrow (Icons.north_east_rounded)
        expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
        expect(find.byIcon(Icons.south_west_rounded), findsNothing);
      },
    );

    testWidgets(
      'currentUserId != callerId shows tilted down arrow for incoming call',
      (tester) async {
        final callModel = CallModel(
          callerId: otherUserId, // other user was caller
          otherUserId: currentUserId,
          otherUserName: 'Dave',
          type: 'audio',
          createdAt: DateTime.now(),
          status: 'incoming',
          duration: 180,
        );
        final callLog = CallLogModel.fromCallModel(callModel);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CallLogItem(
                call: callLog,
                maxWidth: 390,
                currentUserId: currentUserId,
              ),
            ),
          ),
        );

        // Expect tilted down arrow (Icons.south_west_rounded)
        expect(find.byIcon(Icons.south_west_rounded), findsOneWidget);
        expect(find.byIcon(Icons.north_east_rounded), findsNothing);

        final icon = tester.widget<Icon>(find.byIcon(Icons.south_west_rounded));
        expect(icon.color, const Color(0xFFFF6E00));
      },
    );

    testWidgets(
      'currentUserId != callerId shows tilted down arrow for incoming missed call',
      (tester) async {
        final callModel = CallModel(
          callerId: otherUserId, // other user called, user missed it
          otherUserId: currentUserId,
          otherUserName: 'Eve',
          type: 'audio',
          createdAt: DateTime.now(),
          status: 'missed',
          duration: 0,
        );
        final callLog = CallLogModel.fromCallModel(callModel);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CallLogItem(
                call: callLog,
                maxWidth: 390,
                currentUserId: currentUserId,
              ),
            ),
          ),
        );

        // Expect tilted down arrow (Icons.south_west_rounded) in red
        expect(find.byIcon(Icons.south_west_rounded), findsOneWidget);
        expect(find.byIcon(Icons.north_east_rounded), findsNothing);

        final icon = tester.widget<Icon>(find.byIcon(Icons.south_west_rounded));
        expect(icon.color, const Color(0xFFE53935)); // Red for missed
      },
    );

    testWidgets(
      'currentUserId != callerId shows tilted down arrow for ended call from other user',
      (tester) async {
        final callModel = CallModel(
          callerId: otherUserId,
          otherUserId: currentUserId,
          otherUserName: 'Frank',
          type: 'video',
          createdAt: DateTime.now(),
          status: 'ended',
          duration: 60,
        );
        final callLog = CallLogModel.fromCallModel(callModel);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CallLogItem(
                call: callLog,
                maxWidth: 390,
                currentUserId: currentUserId,
              ),
            ),
          ),
        );

        // Expect tilted down arrow (Icons.south_west_rounded)
        expect(find.byIcon(Icons.south_west_rounded), findsOneWidget);
        expect(find.byIcon(Icons.north_east_rounded), findsNothing);
      },
    );

    testWidgets(
      'Fallback when callerId is omitted: outgoing shows tilted upper arrow, missed/incoming shows tilted down arrow',
      (tester) async {
        const outgoingLog = CallLogModel(
          name: 'Outgoing Call',
          callType: CallType.outgoing,
          timeSubtitle: 'Outgoing · 02:00',
          date: 'Today',
          time: '1:00 PM',
          mediaType: CallMediaType.audio,
        );
        const missedLog = CallLogModel(
          name: 'Missed Call',
          callType: CallType.missed,
          timeSubtitle: 'Missed call',
          date: 'Today',
          time: '2:00 PM',
          mediaType: CallMediaType.audio,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CallLogItem(call: outgoingLog, maxWidth: 390),
                  CallLogItem(call: missedLog, maxWidth: 390),
                ],
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
        expect(find.byIcon(Icons.south_west_rounded), findsOneWidget);
      },
    );
  });
}
