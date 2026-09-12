import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'injection.dart';
import 'screens/auth/bloc/auth_bloc.dart';
import 'screens/call/bloc/call_bloc.dart';
import 'screens/contacts/bloc/contact_bloc.dart';
import 'screens/home/bloc/history_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  configureDependencies();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>(),
        ),
        BlocProvider<HistoryBloc>(
          create: (_) =>
              getIt<HistoryBloc>()..add(const HistoryFetchRequested()),
        ),
        BlocProvider<ContactBloc>(
          create: (_) =>
              getIt<ContactBloc>()..add(const ContactFetchRequested()),
        ),
        BlocProvider<CallBloc>(
          create: (_) => getIt<CallBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'ConnectCall',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFFFDF9),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF6E00),
            primary: const Color(0xFFFF6E00),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        routerConfig: appRouter.router,
      ),
    );
  }
}
