import 'package:connectcall/models/profile_model.dart';
import 'package:connectcall/models/user_model.dart';
import 'package:connectcall/screens/auth/bloc/auth_bloc.dart';
import 'package:connectcall/services/firebase/auth.service.dart';
import 'package:connectcall/services/firebase/login.service.dart';
import 'package:connectcall/usecases/auth/login_usecase.dart';
import 'package:connectcall/usecases/auth/signup_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthService extends AuthService {
  FakeAuthService({this.shouldThrow = false});

  final bool shouldThrow;
  UserModel? capturedUser;
  String? capturedName;

  @override
  Future<ProfileModel> signUp(String name, UserModel user) async {
    if (shouldThrow) {
      throw Exception('Sign up failed on server');
    }
    capturedName = name;
    capturedUser = user;
    return ProfileModel(id: 'test-uid-1', name: name, email: user.email);
  }
}

class FakeLoginService extends LoginService {
  FakeLoginService({this.shouldThrow = false});

  final bool shouldThrow;
  UserModel? capturedUser;

  @override
  Future<ProfileModel> loginWithEmailAndPassword(UserModel user) async {
    if (shouldThrow) {
      throw Exception('Login failed on server');
    }
    capturedUser = user;
    return ProfileModel(
      id: 'test-uid-2',
      name: 'Logged In User',
      email: user.email,
    );
  }
}

void main() {
  group('AuthBloc & UseCase Tests', () {
    test('Password mismatch yields failure without calling UseCase', () async {
      final fakeAuth = FakeAuthService();
      final fakeLogin = FakeLoginService();
      final bloc = AuthBloc(
        signUpUseCase: SignUpUseCase(fakeAuth),
        loginUseCase: LoginUseCase(fakeLogin),
      );

      bloc.add(
        const AuthSignUpSubmitted(
          name: 'John Doe',
          email: 'john@example.com',
          password: 'password123',
          confirmPassword: 'differentPassword',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.submitting),
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.failure &&
                s.errorMessage == 'Passwords do not match.',
          ),
        ]),
      );

      expect(fakeAuth.capturedUser, isNull);
      await bloc.close();
    });

    test('AuthSignUpSubmitted converts raw input to UserModel in AuthBloc', () async {
      final fakeAuth = FakeAuthService();
      final fakeLogin = FakeLoginService();
      final bloc = AuthBloc(
        signUpUseCase: SignUpUseCase(fakeAuth),
        loginUseCase: LoginUseCase(fakeLogin),
      );

      bloc.add(
        const AuthSignUpSubmitted(
          name: '  Jane Doe  ',
          email: '  jane@example.com  ',
          password: 'securePassword!',
          confirmPassword: 'securePassword!',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.submitting),
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.success &&
                s.profile?.email == 'jane@example.com' &&
                s.profile?.name == 'Jane Doe',
          ),
        ]),
      );

      // Verify UserModel conversion inside AuthBloc
      expect(fakeAuth.capturedName, equals('Jane Doe'));
      expect(fakeAuth.capturedUser?.email, equals('jane@example.com'));
      expect(fakeAuth.capturedUser?.password, equals('securePassword!'));

      await bloc.close();
    });

    test('AuthLoginSubmitted converts raw input to UserModel in AuthBloc', () async {
      final fakeAuth = FakeAuthService();
      final fakeLogin = FakeLoginService();
      final bloc = AuthBloc(
        signUpUseCase: SignUpUseCase(fakeAuth),
        loginUseCase: LoginUseCase(fakeLogin),
      );

      bloc.add(
        const AuthLoginSubmitted(
          email: '  test@example.com  ',
          password: 'myPassword123',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.submitting),
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.success &&
                s.profile?.email == 'test@example.com',
          ),
        ]),
      );

      // Verify UserModel conversion inside AuthBloc
      expect(fakeLogin.capturedUser?.email, equals('test@example.com'));
      expect(fakeLogin.capturedUser?.password, equals('myPassword123'));

      await bloc.close();
    });

    test('AuthLoginSubmitted failure emits failure state with error', () async {
      final fakeAuth = FakeAuthService();
      final fakeLogin = FakeLoginService(shouldThrow: true);
      final bloc = AuthBloc(
        signUpUseCase: SignUpUseCase(fakeAuth),
        loginUseCase: LoginUseCase(fakeLogin),
      );

      bloc.add(
        const AuthLoginSubmitted(
          email: 'fail@example.com',
          password: 'wrongPassword',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.submitting),
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.failure &&
                s.errorMessage == 'Login failed on server',
          ),
        ]),
      );

      await bloc.close();
    });

    test('AuthResetState deletes all existing state data and resets to initial AuthState', () async {
      final fakeAuth = FakeAuthService();
      final fakeLogin = FakeLoginService();
      final bloc = AuthBloc(
        signUpUseCase: SignUpUseCase(fakeAuth),
        loginUseCase: LoginUseCase(fakeLogin),
      );

      // Populate state with existing data (successful login)
      bloc.add(
        const AuthLoginSubmitted(
          email: 'logged@example.com',
          password: 'password123',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.submitting),
          predicate<AuthState>((s) => s.status == AuthStatus.success && s.profile != null),
        ]),
      );

      expect(bloc.state.profile, isNotNull);
      expect(bloc.state.status, equals(AuthStatus.success));

      // Now dispatch AuthResetState to delete all existing state data
      bloc.add(const AuthResetState());

      await expectLater(
        bloc.stream,
        emits(
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.initial &&
                s.errorMessage == null &&
                s.profile == null,
          ),
        ),
      );

      expect(bloc.state.status, equals(AuthStatus.initial));
      expect(bloc.state.profile, isNull);
      expect(bloc.state.errorMessage, isNull);

      await bloc.close();
    });

    test('ResetState and SignUpResetState aliases delete all existing state data', () async {
      final fakeAuth = FakeAuthService();
      final fakeLogin = FakeLoginService();
      final bloc = AuthBloc(
        signUpUseCase: SignUpUseCase(fakeAuth),
        loginUseCase: LoginUseCase(fakeLogin),
      );

      // Trigger mismatch failure
      bloc.add(
        const AuthSignUpSubmitted(
          name: 'Jane Doe',
          email: 'jane@example.com',
          password: 'pass1',
          confirmPassword: 'pass2',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.submitting),
          predicate<AuthState>((s) => s.status == AuthStatus.failure && s.errorMessage != null),
        ]),
      );

      // Reset using alias ResetState
      bloc.add(const ResetState());

      await expectLater(
        bloc.stream,
        emits(
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.initial &&
                s.errorMessage == null &&
                s.profile == null,
          ),
        ),
      );

      await bloc.close();
    });

    test('AuthSignUpSubmitted deletes all prior state data upon submission', () async {
      final fakeAuth = FakeAuthService();
      final fakeLogin = FakeLoginService();
      final bloc = AuthBloc(
        signUpUseCase: SignUpUseCase(fakeAuth),
        loginUseCase: LoginUseCase(fakeLogin),
      );

      // Populate bloc with a prior login failure
      bloc.add(
        const AuthSignUpSubmitted(
          name: 'Prior User',
          email: 'prior@example.com',
          password: 'pass',
          confirmPassword: 'wrong',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.submitting),
          predicate<AuthState>((s) => s.status == AuthStatus.failure && s.errorMessage != null),
        ]),
      );

      expect(bloc.state.errorMessage, isNotNull);

      // Submitting valid sign up must delete prior errorMessage in submitting state
      bloc.add(
        const AuthSignUpSubmitted(
          name: 'New User',
          email: 'new@example.com',
          password: 'password123',
          confirmPassword: 'password123',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.submitting &&
                s.errorMessage == null &&
                s.profile == null,
          ),
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.success &&
                s.profile?.email == 'new@example.com',
          ),
        ]),
      );

      await bloc.close();
    });
  });
}
