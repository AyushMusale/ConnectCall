import 'package:connectcall/injection.dart';
import 'package:connectcall/main.dart';
import 'package:connectcall/models/profile_model.dart';
import 'package:connectcall/screens/home/home_page.dart';
import 'package:connectcall/screens/splash/splash_screen.dart';
import 'package:connectcall/services/firebase/auth.service.dart';
import 'package:connectcall/services/firebase/session.service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSessionService extends SessionService {
  FakeSessionService({this.isActive = false, this.mockProfile});

  bool isActive;
  ProfileModel? mockProfile;
  bool signedOut = false;

  @override
  bool hasActiveSession() => isActive;

  @override
  bool get isSessionActive => isActive;

  @override
  Future<bool> validateSession() async => isActive;

  @override
  Future<ProfileModel?> getActiveProfile() async => isActive ? mockProfile : null;

  @override
  Future<void> signOut() async {
    signedOut = true;
    isActive = false;
  }
}

class FakeSessionAuthService extends AuthService {
  FakeSessionAuthService({this.isActive = false});

  final bool isActive;

  @override
  bool hasActiveSession() => isActive;

  @override
  bool get isSessionActive => isActive;
}

void main() {
  setUp(() async {
    await getIt.reset();
    configureDependencies();
  });

  group('SessionService Unit Tests', () {
    test('Returns false when no session is active', () {
      final fakeSession = FakeSessionService(isActive: false);
      expect(fakeSession.hasActiveSession(), isFalse);
      expect(fakeSession.isSessionActive, isFalse);
    });

    test('Returns true and loads profile when session is active', () async {
      const profile = ProfileModel(
        id: 'usr-123',
        name: 'Aditi Sharma',
        email: 'aditi@example.com',
      );
      final fakeSession = FakeSessionService(
        isActive: true,
        mockProfile: profile,
      );

      expect(fakeSession.hasActiveSession(), isTrue);
      expect(fakeSession.isSessionActive, isTrue);

      final loadedProfile = await fakeSession.getActiveProfile();
      expect(loadedProfile?.id, equals('usr-123'));
      expect(loadedProfile?.name, equals('Aditi Sharma'));

      final isValid = await fakeSession.validateSession();
      expect(isValid, isTrue);
    });

    test('SignOut terminates the active session', () async {
      final fakeSession = FakeSessionService(isActive: true);
      expect(fakeSession.hasActiveSession(), isTrue);

      await fakeSession.signOut();
      expect(fakeSession.signedOut, isTrue);
      expect(fakeSession.hasActiveSession(), isFalse);
    });

    test('AuthService exposes session check methods', () {
      final authService = FakeSessionAuthService(isActive: true);
      expect(authService.hasActiveSession(), isTrue);
      expect(authService.isSessionActive, isTrue);
    });
  });

  group('SplashScreen Session Navigation Flow', () {
    testWidgets('Navigates to HomePage when active session exists', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Register an active fake session in GetIt
      if (getIt.isRegistered<SessionService>()) {
        getIt.unregister<SessionService>();
      }
      getIt.registerSingleton<SessionService>(
        FakeSessionService(isActive: true),
      );

      await tester.pumpWidget(const MainApp());
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pumpAndSettle();

      // Navigated to HomePage because active session is true
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.textContaining('Connect'), findsWidgets);
      expect(find.textContaining('-Call'), findsWidgets);

      // Reset GetIt
      getIt.unregister<SessionService>();
      configureDependencies();
    });

    testWidgets('Navigates to SignUpPage when no active session exists', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Register an inactive fake session in GetIt
      if (getIt.isRegistered<SessionService>()) {
        getIt.unregister<SessionService>();
      }
      getIt.registerSingleton<SessionService>(
        FakeSessionService(isActive: false),
      );

      await tester.pumpWidget(const MainApp());
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pumpAndSettle();

      // Navigated to SignUpPage because active session is false
      expect(find.text('Create Account'), findsWidgets);

      // Reset GetIt
      getIt.unregister<SessionService>();
      configureDependencies();
    });
  });
}
