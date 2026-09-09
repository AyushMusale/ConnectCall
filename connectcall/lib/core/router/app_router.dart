import 'package:go_router/go_router.dart';

import '../../screens/auth/login_page.dart';
import '../../screens/auth/signup_page.dart';

class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: '/signup',
    routes: [
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );
}
