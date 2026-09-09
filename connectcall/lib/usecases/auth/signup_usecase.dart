import '../../models/profile_model.dart';
import '../../models/user_model.dart';
import '../../services/firebase/auth.service.dart';

/// UseCase responsible for user registration / sign up.
class SignUpUseCase {
  const SignUpUseCase(this._authService);

  final AuthService _authService;

  /// Executes sign up using display [name] and [user] credentials.
  Future<ProfileModel> execute({
    required String name,
    required UserModel user,
  }) {
    return _authService.signUp(name, user);
  }
}
