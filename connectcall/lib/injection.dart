import 'package:get_it/get_it.dart';

import 'core/router/app_router.dart';
import 'screens/auth/bloc/auth_bloc.dart';
import 'services/firebase/auth.service.dart';
import 'services/firebase/login.service.dart';
import 'usecases/auth/login_usecase.dart';
import 'usecases/auth/signup_usecase.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Services
  if (!getIt.isRegistered<AuthService>()) {
    getIt.registerLazySingleton<AuthService>(AuthService.new);
  }

  if (!getIt.isRegistered<LoginService>()) {
    getIt.registerLazySingleton<LoginService>(LoginService.new);
  }

  // UseCases
  if (!getIt.isRegistered<SignUpUseCase>()) {
    getIt.registerLazySingleton<SignUpUseCase>(
      () => SignUpUseCase(getIt<AuthService>()),
    );
  }

  if (!getIt.isRegistered<LoginUseCase>()) {
    getIt.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(getIt<LoginService>()),
    );
  }

  // BLoC
  if (!getIt.isRegistered<AuthBloc>()) {
    getIt.registerFactory<AuthBloc>(
      () => AuthBloc(
        signUpUseCase: getIt<SignUpUseCase>(),
        loginUseCase: getIt<LoginUseCase>(),
      ),
    );
  }

  // Router
  if (!getIt.isRegistered<AppRouter>()) {
    getIt.registerSingleton<AppRouter>(AppRouter());
  }
}

AppRouter get appRouter => getIt<AppRouter>();
