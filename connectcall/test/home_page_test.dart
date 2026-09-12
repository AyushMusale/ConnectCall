import 'package:connectcall/injection.dart';
import 'package:connectcall/screens/home/home_page.dart';
import 'package:connectcall/screens/home/widgets/call_filter_chips.dart';
import 'package:connectcall/screens/home/widgets/call_log_item.dart';
import 'package:connectcall/widgets/app_bottom_nav.dart';
import 'package:connectcall/widgets/app_header.dart';
import 'package:connectcall/screens/home/widgets/home_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    configureDependencies();
  });

  group('HomePage UI & Elements', () {
    testWidgets('Renders header, search bar, chips, call list, and bottom dock', (
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

      // 1. Header
      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.textContaining('Connect'), findsWidgets);
      expect(find.textContaining('-Call'), findsWidgets);
      expect(find.text('Stay close, no matter the distance'), findsOneWidget);
      expect(find.text('Contacts'), findsWidgets);

      // 2. Search Bar
      expect(find.byType(HomeSearchBar), findsOneWidget);
      expect(find.text('Search contacts...'), findsOneWidget);

      // 3. Filter Chips
      expect(find.byType(CallFilterChips), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Missed'), findsOneWidget);
      expect(find.text('Incoming'), findsOneWidget);
      expect(find.text('Outgoing'), findsOneWidget);

      // 4. Call log entries
      expect(find.byType(CallLogItem), findsWidgets);
      expect(find.text('Aditi Sharma'), findsOneWidget);
      expect(find.text('Rohan Mehta'), findsOneWidget);
      expect(find.text('Priya Nair'), findsOneWidget);

      // 5. Floating Bottom Nav
      expect(find.byType(HomeBottomNav), findsOneWidget);
      expect(find.text('Calls'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Filters call list when selecting a filter chip', (
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

      // Tap "Missed" filter chip
      await tester.tap(find.text('Missed'));
      await tester.pumpAndSettle();

      // Should find missed calls: Rohan Mehta, Sneha Patil
      expect(find.text('Rohan Mehta'), findsOneWidget);
      expect(find.text('Sneha Patil'), findsOneWidget);
      // Non-missed call should not appear
      expect(find.text('Aditi Sharma'), findsNothing);
    });

    testWidgets('Filters call list when typing in search bar', (
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

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Priya');
      await tester.pumpAndSettle();

      expect(find.text('Priya Nair'), findsOneWidget);
      expect(find.text('Aditi Sharma'), findsNothing);
    });

    testWidgets(
      'Tapping three-dots button opens menu with Sign Out option and triggers sign out',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool signedOutCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeHeader(
                maxWidth: 390,
                onSignOut: () {
                  signedOutCalled = true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Sign Out option shouldn't be visible initially
        expect(find.text('Sign Out'), findsNothing);

        // Tap the three dots icon (more_vert_rounded)
        final moreButton = find.byIcon(Icons.more_vert_rounded);
        expect(moreButton, findsOneWidget);
        await tester.tap(moreButton);
        await tester.pumpAndSettle();

        // Sign Out option should now appear
        expect(find.text('Sign Out'), findsOneWidget);

        // Tap Sign Out option
        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();

        // Verify sign out was triggered
        expect(signedOutCalled, isTrue);
      },
    );

    testWidgets('HomePage three-dots button displays Sign Out menu option', (
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

      final moreButton = find.byIcon(Icons.more_vert_rounded);
      expect(moreButton, findsOneWidget);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsOneWidget);
    });
  });

  group('HomePage LayoutBuilder & Clamp Responsiveness', () {
    const testDevices = <String, Size>{
      'Small Budget Phone (320x568)': Size(320, 568),
      'iPhone SE / Compact (375x667)': Size(375, 667),
      'Standard Android (360x780)': Size(360, 780),
      'iPhone 14/15/16 (390x844)': Size(390, 844),
      'Large Pro Max Phone (430x932)': Size(430, 932),
      'Foldable Open / Tablet (768x1024)': Size(768, 1024),
      'Desktop / Laptop (1280x800)': Size(1280, 800),
    };

    for (final entry in testDevices.entries) {
      testWidgets('Renders HomePage without overflow on ${entry.key}', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(HomeHeader), findsOneWidget);
        expect(find.byType(HomeSearchBar), findsOneWidget);
        expect(find.byType(CallFilterChips), findsOneWidget);
        expect(find.byType(HomeBottomNav), findsOneWidget);
      });
    }
  });
}
