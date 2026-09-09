import 'package:connectcall/injection.dart';
import 'package:connectcall/main.dart';
import 'package:connectcall/screens/auth/login_page.dart';
import 'package:connectcall/screens/auth/widgets/auth_illustration.dart';
import 'package:connectcall/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    configureDependencies();
  });

  const testDevices = <String, Size>{
    'Small Budget Phone (320x568)': Size(320, 568),
    'iPhone SE / Compact (375x667)': Size(375, 667),
    'Standard Android (360x780)': Size(360, 780),
    'iPhone 14/15/16 (390x844)': Size(390, 844),
    'Large Pro Max Phone (430x932)': Size(430, 932),
    'Foldable Open / Tablet (768x1024)': Size(768, 1024),
    'Desktop / Laptop (1280x800)': Size(1280, 800),
  };

  group('SignUpPage Responsiveness', () {
    for (final entry in testDevices.entries) {
      testWidgets('Renders SignUp without overflow on ${entry.key}', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MainApp());
        await tester.pumpAndSettle();

        // Ensure no exceptions or overflows
        expect(tester.takeException(), isNull);
        expect(find.byType(AuthIllustration), findsWidgets);
        expect(find.byType(CommonButton), findsOneWidget);
        expect(find.text('Create Account'), findsWidgets);
      });
    }
  });

  group('LoginPage Responsiveness', () {
    for (final entry in testDevices.entries) {
      testWidgets('Renders Login without overflow on ${entry.key}', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: LoginPage()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AuthIllustration), findsOneWidget);
        expect(find.byType(CommonButton), findsOneWidget);
        expect(find.text('Welcome Back'), findsOneWidget);
      });
    }
  });
}
