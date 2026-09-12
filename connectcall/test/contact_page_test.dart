import 'package:connectcall/injection.dart';
import 'package:connectcall/screens/contacts/contact_page.dart';
import 'package:connectcall/screens/contacts/widgets/contact_list_item.dart';
import 'package:connectcall/widgets/app_bottom_nav.dart';
import 'package:connectcall/screens/home/widgets/home_search_bar.dart';
import 'package:connectcall/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    configureDependencies();
  });

  group('ContactPage UI & Elements', () {
    testWidgets('Renders AppHeader, search bar, contact list, and bottom dock with Contacts selected', (
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

      // 1. AppHeader
      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.textContaining('Connect'), findsWidgets);
      expect(find.textContaining('-Call'), findsWidgets);
      expect(find.text('Stay close, no matter the distance'), findsOneWidget);
      expect(find.text('Contacts'), findsWidgets);

      // 2. Search Bar
      expect(find.byType(HomeSearchBar), findsOneWidget);
      expect(find.text('Search contacts...'), findsOneWidget);

      // 3. Contact list entries matching contact page.png
      expect(find.byType(ContactListItem), findsWidgets);
      expect(find.text('Aditi Sharma'), findsOneWidget);
      expect(find.text('Rohan Mehta'), findsOneWidget);
      expect(find.text('Priya Nair'), findsOneWidget);
      expect(find.text('College Buddies'), findsOneWidget);
      expect(find.text('Karan Desai'), findsOneWidget);
      expect(find.text('Sneha Patil'), findsOneWidget);

      // 4. Floating Bottom Navigation with Contacts active
      expect(find.byType(HomeBottomNav), findsOneWidget);
      expect(find.text('Calls'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Filters contacts list when typing in search bar', (
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

      // Type "Meera" in search
      await tester.enterText(find.byType(TextField), 'Meera');
      await tester.pumpAndSettle();

      expect(find.text('Meera Iyer'), findsOneWidget);
      expect(find.text('Aditi Sharma'), findsNothing);
      expect(find.text('Rohan Mehta'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('Aditi Sharma'), findsOneWidget);
      expect(find.text('Rohan Mehta'), findsOneWidget);
    });

    testWidgets('Tapping three-dots menu reveals Sign Out option', (
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

      final moreButton = find.byIcon(Icons.more_vert_rounded);
      expect(moreButton, findsOneWidget);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsOneWidget);
    });
  });

  group('ContactPage LayoutBuilder & Clamp Responsiveness', () {
    final testDevices = <String, Size>{
      'Small Budget Phone (320x568)': const Size(320, 568),
      'iPhone SE / Compact (375x667)': const Size(375, 667),
      'Standard Android (360x780)': const Size(360, 780),
      'iPhone 14/15/16 (390x844)': const Size(390, 844),
      'Large Pro Max Phone (430x932)': const Size(430, 932),
      'Foldable Open / Tablet (768x1024)': const Size(768, 1024),
      'Desktop / Laptop (1280x800)': const Size(1280, 800),
    };

    for (final entry in testDevices.entries) {
      testWidgets('Renders ContactPage without overflow on ${entry.key}', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: ContactPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AppHeader), findsOneWidget);
        expect(find.byType(HomeSearchBar), findsOneWidget);
        expect(find.byType(HomeBottomNav), findsOneWidget);
      });
    }
  });
}
