import 'package:connectcall/injection.dart';
import 'package:connectcall/screens/call/make_call_page.dart';
import 'package:connectcall/screens/call/widgets/make_call_bottom_sheet.dart';
import 'package:connectcall/screens/contacts/contact_page.dart';
import 'package:connectcall/screens/home/home_page.dart';
import 'package:connectcall/widgets/app_bottom_nav.dart';
import 'package:connectcall/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    configureDependencies();
  });

  group('MakeCallPage UI & Elements', () {
    testWidgets('Renders AppHeader, contact details, action cards, and NO bottom navbar', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MakeCallPage(
            contactName: 'Aditi Sharma',
            isOnline: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. AppHeader present
      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.textContaining('Connect'), findsWidgets);
      expect(find.textContaining('-Call'), findsWidgets);
      expect(find.text('Stay close, no matter the distance'), findsOneWidget);
      expect(find.text('Contacts'), findsOneWidget);

      // 2. NO Bottom Navbar present
      expect(find.byType(AppBottomNav), findsNothing);
      expect(find.byType(HomeBottomNav), findsNothing);

      // 3. Close button
      expect(find.text('Close'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // 4. Contact details & Online status
      expect(find.text('Aditi Sharma'), findsWidgets);
      expect(find.text('Online'), findsOneWidget);

      // 5. Action cards: Audio Call & Video Call
      expect(find.text('Audio Call'), findsOneWidget);
      expect(find.byIcon(Icons.call_rounded), findsOneWidget);
      expect(find.text('Video Call'), findsOneWidget);
      expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
    });

    testWidgets('Audio Call and Video Call buttons trigger callbacks', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool audioCalled = false;
      bool videoCalled = false;
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MakeCallPage(
            contactName: 'Rohan Mehta',
            onAudioCall: () => audioCalled = true,
            onVideoCall: () => videoCalled = true,
            onClose: () => closed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Audio Call'));
      await tester.pump();
      expect(audioCalled, isTrue);

      await tester.tap(find.text('Video Call'));
      await tester.pump();
      expect(videoCalled, isTrue);

      await tester.tap(find.text('Close'));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('Clicking a contact card in ContactPage opens MakeCallBottomSheet directly without redirecting', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ContactPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Aditi Sharma contact item
      await tester.tap(find.text('Aditi Sharma').first);
      await tester.pumpAndSettle();

      // Verify ContactPage remains in background and MakeCallBottomSheet is opened directly
      expect(find.byType(ContactPage), findsOneWidget);
      expect(find.byType(MakeCallBottomSheet), findsOneWidget);
      expect(find.text('Audio Call'), findsOneWidget);
      expect(find.text('Video Call'), findsOneWidget);

      // Verify closing the bottom sheet
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(MakeCallBottomSheet), findsNothing);
      expect(find.byType(ContactPage), findsOneWidget);
    });

    testWidgets('Clicking a call log in HomePage opens MakeCallBottomSheet directly without redirecting', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on first call log item (Aditi Sharma)
      await tester.tap(find.text('Aditi Sharma').first);
      await tester.pumpAndSettle();

      // Verify HomePage remains, ContactPage is NOT opened, and MakeCallBottomSheet is shown directly
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(ContactPage), findsNothing);
      expect(find.byType(MakeCallBottomSheet), findsOneWidget);
      expect(find.text('Audio Call'), findsOneWidget);
      expect(find.text('Video Call'), findsOneWidget);

      // Verify closing the bottom sheet
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(MakeCallBottomSheet), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('MakeCallPage renders without overflow on multiple screen sizes', (
      WidgetTester tester,
    ) async {
      final testSizes = [
        const Size(320, 568), // Small budget
        const Size(375, 667), // iPhone SE
        const Size(390, 844), // iPhone 14/15
        const Size(430, 932), // Pro Max
        const Size(768, 1024), // Tablet
        const Size(1280, 800), // Laptop/Desktop
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: MakeCallPage(
              contactName: 'Sneha Patil',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MakeCallPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
