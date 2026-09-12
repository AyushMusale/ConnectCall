import 'package:connectcall/injection.dart';
import 'package:connectcall/main.dart';
import 'package:connectcall/screens/splash/splash_screen.dart';
import 'package:connectcall/screens/splash/widgets/splash_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    configureDependencies();
  });

  group('SplashScreen UI & Elements', () {
    testWidgets('Renders all brand, typography, and setup elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
            autoNavigate: false,
          ),
        ),
      );

      // Verify custom background painter
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify SplashLogo emblem
      expect(find.byType(SplashLogo), findsOneWidget);

      // Verify two-tone title: Connect + -Call
      expect(find.textContaining('Connect'), findsWidgets);
      expect(find.textContaining('-Call'), findsWidgets);

      // Verify Tagline
      expect(find.text('Stay close, no matter the distance'), findsOneWidget);

      // Verify Status label
      expect(find.text('Setting things up for you...'), findsOneWidget);
    });

    testWidgets('Animates progress and triggers callback on completion', (
      WidgetTester tester,
    ) async {
      var completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(milliseconds: 500),
            autoNavigate: false,
            onInitializationComplete: () {
              completed = true;
            },
          ),
        ),
      );

      expect(completed, isFalse);

      // Advance halfway
      await tester.pump(const Duration(milliseconds: 250));
      expect(completed, isFalse);

      // Advance past completion
      await tester.pump(const Duration(milliseconds: 300));
      expect(completed, isTrue);
    });
  });

  group('SplashScreen Responsiveness', () {
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
      testWidgets('Renders without overflow on ${entry.key}', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: SplashScreen(
              autoNavigate: false,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        expect(find.byType(SplashLogo), findsOneWidget);
        expect(find.text('Setting things up for you...'), findsOneWidget);
      });
    }
  });

  group('App Integration Flow', () {
    testWidgets('MainApp starts on SplashScreen and navigates to SignUpPage', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MainApp());

      // Initial screen is SplashScreen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(SplashLogo), findsOneWidget);

      // Settle all timers and animations
      await tester.pumpAndSettle();

      // After splash duration completes, app navigates to SignUpPage
      expect(find.text('Create Account'), findsWidgets);
    });
  });
}
