import '../../../models/profile_model.dart';

enum AuthStatus {
  initial,
  submitting,
  success,
  failure,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.profile,
  });

  final AuthStatus status;
  final String? errorMessage;
  final ProfileModel? profile;

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    ProfileModel? profile,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      profile: profile ?? this.profile,
    );
  }
}
