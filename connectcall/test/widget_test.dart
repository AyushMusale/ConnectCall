import 'package:connectcall/injection.dart';
import 'package:connectcall/main.dart';
import 'package:connectcall/screens/auth/login_page.dart';
import 'package:connectcall/screens/auth/widgets/auth_illustration.dart';
import 'package:connectcall/widgets/brand_logo.dart';
import 'package:connectcall/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    configureDependencies();
  });

  testWidgets('Renders SignUp page with branding, form, and illustration', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    // Verify Brand logo exists
    expect(find.byType(BrandLogo), findsWidgets);

    // Verify Header text exists
    expect(find.textContaining('Connect'), findsWidgets);
    expect(find.textContaining('anywhere.'), findsWidgets);

    // Verify Illustration exists
    expect(find.byType(AuthIllustration), findsWidgets);

    // Verify Form Fields exist
    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);

    // Verify Submit button exists
    expect(find.byType(CommonButton), findsOneWidget);

    // Verify Login footer link exists
    expect(find.textContaining('Already have an account?'), findsOneWidget);
  });

  testWidgets('Shows validation errors when submitting empty form', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    final submitButton = find.byType(CommonButton);
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Validation messages should appear
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
  });

  testWidgets('Navigates from SignUp to Login and back via GoRouter', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    // Find and tap "Login" link
    final loginLink = find.textContaining('Already have an account?');
    await tester.ensureVisible(loginLink);
    await tester.tap(loginLink);
    await tester.pumpAndSettle();

    // Should now be on LoginPage
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);

    // Tap "Sign Up" to return
    final signUpLink = find.textContaining("Don't have an account?");
    await tester.ensureVisible(signUpLink);
    await tester.tap(signUpLink);
    await tester.pumpAndSettle();

    // Should now be back on SignUp
    expect(find.text('Create Account'), findsWidgets);
  });
}
