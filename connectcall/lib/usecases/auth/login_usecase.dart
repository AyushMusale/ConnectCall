import '../../models/profile_model.dart';
import '../../models/user_model.dart';
import '../../services/firebase/login.service.dart';

/// UseCase responsible for user authentication / login.
class LoginUseCase {
  const LoginUseCase(this._loginService);

  final LoginService _loginService;

  /// Executes login using credentials from [user].
  Future<ProfileModel> execute(UserModel user) {
    return _loginService.loginWithEmailAndPassword(user);
  }
}
