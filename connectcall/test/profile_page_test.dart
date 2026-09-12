import 'package:connectcall/injection.dart';
import 'package:connectcall/models/profile_model.dart';
import 'package:connectcall/screens/profile/profile_page.dart';
import 'package:connectcall/services/firebase/profile.service.dart';
import 'package:connectcall/widgets/app_bottom_nav.dart';
import 'package:connectcall/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_service_test.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  Widget buildTestWidget({ProfileService? service}) {
    return MaterialApp(
      home: ProfilePage(
        profileServiceOverride: service,
      ),
    );
  }

  group('ProfilePage Widget Tests', () {
    testWidgets('Renders all elements matching profile.png accurately', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeService = FakeProfileService(
        initialName: 'Ayush Sharma',
        currentEmail: 'ayush.sharma@example.com',
      );

      await tester.pumpWidget(buildTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      // 1. App Header
      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.textContaining('Connect'), findsWidgets);
      expect(find.textContaining('-Call'), findsWidgets);
      expect(find.text('Stay close, no matter the distance'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      // 2. Avatar & Camera Badge
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);

      // 3. Email subtitle
      expect(find.text('ayush.sharma@example.com'), findsOneWidget);

      // 4. Name input field and label
      expect(find.text('Name'), findsOneWidget);
      expect(find.byKey(const Key('profile_name_input')), findsOneWidget);
      expect(find.text('Ayush Sharma'), findsOneWidget);

      // 5. Save Button
      expect(find.byKey(const Key('profile_save_button')), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // 6. Log Out Button
      expect(find.byKey(const Key('profile_logout_button')), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

      // 7. Bottom Navigation with Profile selected
      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Calls'), findsOneWidget);
      expect(find.text('Contacts'), findsOneWidget);
    });

    testWidgets('Saving updated name invokes updateName and displays snackbar', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeService = FakeProfileService(
        initialName: 'Ayush Sharma',
        currentEmail: 'ayush.sharma@example.com',
      );

      await tester.pumpWidget(buildTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      // Clear and enter new name
      final inputFinder = find.byKey(const Key('profile_name_input'));
      await tester.enterText(inputFinder, 'Ayush Kumar');
      await tester.pump();

      // Tap Save button
      final saveButtonFinder = find.byKey(const Key('profile_save_button'));
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      // Verify service updated
      final updatedProfile = await fakeService.getProfile();
      expect(updatedProfile?.name, equals('Ayush Kumar'));

      // Verify success snackbar
      expect(find.text('Profile updated successfully!'), findsOneWidget);
    });

    testWidgets('Empty name displays error snackbar and does not save', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeService = FakeProfileService(
        initialName: 'Ayush Sharma',
      );

      await tester.pumpWidget(buildTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      // Clear name
      final inputFinder = find.byKey(const Key('profile_name_input'));
      await tester.enterText(inputFinder, '');
      await tester.pump();

      // Tap Save button
      final saveButtonFinder = find.byKey(const Key('profile_save_button'));
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      // Verify error snackbar
      expect(find.text('Name cannot be empty.'), findsOneWidget);
      // Service still has original name
      final profile = await fakeService.getProfile();
      expect(profile?.name, equals('Ayush Sharma'));
    });

    testWidgets('Tapping Log Out invokes signOut on ProfileService', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeService = FakeProfileService(
        initialName: 'Ayush Sharma',
      );

      await tester.pumpWidget(buildTestWidget(service: fakeService));
      await tester.pumpAndSettle();

      expect(fakeService.signedOut, isFalse);

      final logoutButtonFinder = find.byKey(const Key('profile_logout_button'));
      await tester.tap(logoutButtonFinder);
      await tester.pump();

      expect(fakeService.signedOut, isTrue);
    });
  });
}
