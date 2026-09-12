import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/user_model.dart';
import '../../../usecases/auth/login_usecase.dart';
import '../../../usecases/auth/signup_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignUpUseCase signUpUseCase,
    required LoginUseCase loginUseCase,
  })  : _signUpUseCase = signUpUseCase,
        _loginUseCase = loginUseCase,
        super(const AuthState()) {
    on<AuthSignUpSubmitted>(_onSignUpSubmitted);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthResetState>(_onResetState);
  }

  final SignUpUseCase _signUpUseCase;
  final LoginUseCase _loginUseCase;

  Future<void> _onSignUpSubmitted(
    AuthSignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    // Delete all existing state data and start fresh in submitting state
    emit(const AuthState(status: AuthStatus.submitting));

    // Basic business validation
    if (event.password != event.confirmPassword) {
      emit(const AuthState(
        status: AuthStatus.failure,
        errorMessage: 'Passwords do not match.',
      ));
      return;
    }

    try {
      // Map raw inputs to domain UserModel inside BLoC
      final user = UserModel(
        email: event.email.trim(),
        password: event.password,
      );

      final profile = await _signUpUseCase.execute(
        name: event.name.trim(),
        user: user,
      );

      emit(AuthState(
        status: AuthStatus.success,
        profile: profile,
      ));
    } on FirebaseAuthException catch (e) {
      emit(AuthState(
        status: AuthStatus.failure,
        errorMessage: e.message ?? 'Sign up failed.',
      ));
    } catch (e) {
      emit(AuthState(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception: '), ''),
      ));
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    // Delete all existing state data and start fresh in submitting state
    emit(const AuthState(status: AuthStatus.submitting));

    try {
      // Map raw inputs to domain UserModel inside BLoC
      final user = UserModel(
        email: event.email.trim(),
        password: event.password,
      );

      final profile = await _loginUseCase.execute(user);

      emit(AuthState(
        status: AuthStatus.success,
        profile: profile,
      ));
    } on FirebaseAuthException catch (e) {
      emit(AuthState(
        status: AuthStatus.failure,
        errorMessage: e.message ?? 'Login failed.',
      ));
    } catch (e) {
      emit(AuthState(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception: '), ''),
      ));
    }
  }

  void _onResetState(
    AuthResetState event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    emit(const AuthState.initial());
  }
}

/// Alias for [AuthBloc] when referred to as [SignUpBloc].
typedef SignUpBloc = AuthBloc;

