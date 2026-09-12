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

  /// Factory constructor to delete/reset all existing state data to initial values.
  const AuthState.initial()
      : status = AuthStatus.initial,
        errorMessage = null,
        profile = null;

  final AuthStatus status;
  final String? errorMessage;
  final ProfileModel? profile;

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    ProfileModel? profile,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      profile: clearProfile ? null : (profile ?? this.profile),
    );
  }
}
