sealed class AuthEvent {
  const AuthEvent();
}

/// Dispatched when the user submits the sign up form with all entered details.
class AuthSignUpSubmitted extends AuthEvent {
  const AuthSignUpSubmitted({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  final String name;
  final String email;
  final String password;
  final String confirmPassword;
}

/// Dispatched when the user submits the login form with email and password.
class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

/// Dispatched to reset the auth status back to initial state.
class AuthResetState extends AuthEvent {
  const AuthResetState();
}
