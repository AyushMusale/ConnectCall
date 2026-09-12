import 'package:get_it/get_it.dart';

import 'core/router/app_router.dart';
import 'screens/auth/bloc/auth_bloc.dart';
import 'screens/call/bloc/call_bloc.dart';
import 'screens/contacts/bloc/contact_bloc.dart';
import 'screens/home/bloc/history_bloc.dart';
import 'services/calls.service.dart';
import 'services/firebase/auth.service.dart';
import 'services/firebase/contact.service.dart';
import 'services/firebase/history.service.dart';
import 'services/firebase/login.service.dart';
import 'services/firebase/profile.service.dart';
import 'services/firebase/search.service.dart';
import 'services/firebase/session.service.dart';
import 'services/firebase/signaling.service.dart';
import 'services/permissions.service.dart';
import 'services/webRTC.service.dart';
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

  if (!getIt.isRegistered<SessionService>()) {
    getIt.registerLazySingleton<SessionService>(SessionService.new);
  }

  if (!getIt.isRegistered<ProfileService>()) {
    getIt.registerLazySingleton<ProfileService>(ProfileService.new);
  }

  if (!getIt.isRegistered<SearchService>()) {
    getIt.registerLazySingleton<SearchService>(SearchService.new);
  }

  if (!getIt.isRegistered<HomeService>()) {
    getIt.registerLazySingleton<HomeService>(HomeService.new);
  }

  if (!getIt.isRegistered<HistoryService>()) {
    getIt.registerLazySingleton<HistoryService>(
      () => HistoryService.fromHomeService(getIt<HomeService>()),
    );
  }

  if (!getIt.isRegistered<ContactService>()) {
    getIt.registerLazySingleton<ContactService>(ContactService.new);
  }

  if (!getIt.isRegistered<WebRTCService>()) {
    getIt.registerLazySingleton<WebRTCService>(WebRTCService.new);
  }

  if (!getIt.isRegistered<PermissionsService>()) {
    getIt.registerLazySingleton<PermissionsService>(PermissionsService.new);
  }

  if (!getIt.isRegistered<SignalingService>()) {
    getIt.registerLazySingleton<SignalingService>(SignalingService.new);
  }

  if (!getIt.isRegistered<CallsService>()) {
    getIt.registerLazySingleton<CallsService>(
      () => CallsService(
        webRTCService: getIt<WebRTCService>(),
        signalingService: getIt<SignalingService>(),
      ),
    );
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

  if (!getIt.isRegistered<ContactBloc>()) {
    getIt.registerFactory<ContactBloc>(
      () => ContactBloc(contactService: getIt<ContactService>()),
    );
  }

  if (!getIt.isRegistered<HistoryBloc>()) {
    getIt.registerFactory<HistoryBloc>(
      () => HistoryBloc(historyService: getIt<HistoryService>()),
    );
  }

  if (!getIt.isRegistered<CallBloc>()) {
    getIt.registerFactory<CallBloc>(
      () => CallBloc(
        callsService: getIt<CallsService>(),
        signalingService: getIt<SignalingService>(),
        historyService: getIt<HistoryService>(),
        sessionService: getIt<SessionService>(),
      ),
    );
  }

  // Router
  if (!getIt.isRegistered<AppRouter>()) {
    getIt.registerSingleton<AppRouter>(AppRouter());
  }
}

AppRouter get appRouter => getIt<AppRouter>();
SessionService get sessionService => getIt<SessionService>();
SearchService get searchService => getIt<SearchService>();
HomeService get homeService => getIt<HomeService>();
HistoryService get historyService => getIt<HistoryService>();
ContactService get contactService => getIt<ContactService>();
WebRTCService get webRTCService => getIt<WebRTCService>();
PermissionsService get permissionsService => getIt<PermissionsService>();
SignalingService get signalingService => getIt<SignalingService>();
CallsService get callsService => getIt<CallsService>();
ProfileService get profileService => getIt<ProfileService>();
CallBloc get callBloc => getIt<CallBloc>();

