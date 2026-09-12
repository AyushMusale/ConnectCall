import 'package:go_router/go_router.dart';

import '../../models/call_model.dart';
import '../../screens/auth/login_page.dart';
import '../../screens/auth/signup_page.dart';
import '../../screens/call/bloc/call_bloc.dart';
import '../../screens/call/make_call_page.dart';
import '../../screens/call/on_call_page.dart';
import '../../screens/call/pickup_call_page.dart';
import '../../screens/contacts/contact_page.dart';
import '../../screens/contacts/models/contact_model.dart';
import '../../screens/home/home_page.dart';
import '../../screens/home/models/call_log_model.dart';
import '../../screens/splash/splash_screen.dart';

class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/splash',
        redirect: (context, state) => '/',
      ),
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
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/contacts',
        name: 'contacts',
        builder: (context, state) => const ContactPage(),
      ),
      GoRoute(
        path: '/make-call',
        name: 'make-call',
        builder: (context, state) {
          final extra = state.extra;
          String name = 'Aditi Sharma';
          String? avatarUrl =
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';
          bool isOnline = true;
          bool autoStart = false;
          String callType = 'audio';

          String otherUserId = 'cnt-1';

          if (extra is ContactModel) {
            name = extra.name;
            avatarUrl = extra.avatarUrl;
            otherUserId = extra.otherUserId;
          } else if (extra is CallLogModel) {
            name = extra.name;
            avatarUrl = extra.avatarUrl;
            otherUserId = extra.callModel?.otherUserId ?? otherUserId;
          } else if (extra is CallModel) {
            name = extra.otherUserName;
            avatarUrl = extra.otherUserAvatar;
            otherUserId = extra.otherUserId;
          } else if (extra is Map) {
            name = (extra['name'] ?? extra['otherUserName'] ?? name).toString();
            avatarUrl = extra['avatarUrl'] as String? ??
                extra['otherUserAvatar'] as String? ??
                avatarUrl;
            if (extra['otherUserId'] != null) {
              otherUserId = extra['otherUserId'].toString();
            } else if (extra['id'] != null) {
              otherUserId = extra['id'].toString();
            }
            if (extra['isOnline'] is bool) {
              isOnline = extra['isOnline'] as bool;
            }
            if (extra['autoStart'] is bool) {
              autoStart = extra['autoStart'] as bool;
            }
            if (extra['type'] != null) {
              callType = extra['type'].toString();
            } else if (extra['callType'] != null) {
              callType = extra['callType'].toString();
            }
          }

          return MakeCallPage(
            otherUserId: otherUserId,
            contactName: name,
            avatarUrl: avatarUrl,
            isOnline: isOnline,
            autoStart: autoStart,
            callType: callType,
          );
        },
      ),
      GoRoute(
        path: '/on-call',
        name: 'on-call',
        builder: (context, state) {
          final extra = state.extra;
          String otherUserId = 'cnt-1';
          String name = 'Aditi Sharma';
          String? avatarUrl =
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';
          String type = 'audio';

          if (extra is ContactModel) {
            name = extra.name;
            avatarUrl = extra.avatarUrl;
            otherUserId = extra.otherUserId;
          } else if (extra is CallLogModel) {
            name = extra.name;
            avatarUrl = extra.avatarUrl;
            otherUserId = extra.callModel?.otherUserId ?? otherUserId;
            type = extra.mediaType == CallMediaType.video ? 'video' : 'audio';
          } else if (extra is CallModel) {
            name = extra.otherUserName;
            avatarUrl = extra.otherUserAvatar;
            otherUserId = extra.otherUserId;
            type = extra.type;
          } else if (extra is Map) {
            name = (extra['name'] ?? extra['otherUserName'] ?? name).toString();
            avatarUrl = extra['avatarUrl'] as String? ??
                extra['otherUserAvatar'] as String? ??
                avatarUrl;
            if (extra['otherUserId'] != null) {
              otherUserId = extra['otherUserId'].toString();
            } else if (extra['id'] != null) {
              otherUserId = extra['id'].toString();
            }
            if (extra['callType'] != null) {
              type = extra['callType'].toString();
            } else if (extra['type'] != null) {
              type = extra['type'].toString();
            }
            bool isIncoming = false;
            String? callId;
            if (extra['isIncoming'] is bool) {
              isIncoming = extra['isIncoming'] as bool;
            }
            if (extra['callId'] != null) {
              callId = extra['callId'].toString();
            }
            CallBloc? bloc;
            if (extra['callBloc'] is CallBloc) {
              bloc = extra['callBloc'] as CallBloc;
            }

            return OnCallPage(
              otherUserId: otherUserId,
              contactName: name,
              avatarUrl: avatarUrl,
              callType: type,
              callId: callId,
              isIncoming: isIncoming,
              callBloc: bloc,
            );
          }

          return OnCallPage(
            otherUserId: otherUserId,
            contactName: name,
            avatarUrl: avatarUrl,
            callType: type,
          );
        },
      ),
      GoRoute(
        path: '/pickup-call',
        name: 'pickup-call',
        builder: (context, state) {
          final extra = state.extra;
          String otherUserId = 'cnt-1';
          String name = 'Aditi Sharma';
          String? avatarUrl =
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150';
          String type = 'audio';
          String? callId;

          if (extra is ContactModel) {
            name = extra.name;
            avatarUrl = extra.avatarUrl;
            otherUserId = extra.otherUserId;
          } else if (extra is CallLogModel) {
            name = extra.name;
            avatarUrl = extra.avatarUrl;
            otherUserId = extra.callModel?.otherUserId ?? otherUserId;
            type = extra.mediaType == CallMediaType.video ? 'video' : 'audio';
            callId = extra.callModel?.id;
          } else if (extra is CallModel) {
            name = extra.otherUserName;
            avatarUrl = extra.otherUserAvatar;
            otherUserId = extra.otherUserId;
            type = extra.type;
            callId = extra.id;
          } else if (extra is Map) {
            name = (extra['name'] ??
                    extra['contactName'] ??
                    extra['otherUserName'] ??
                    name)
                .toString();
            avatarUrl = extra['avatarUrl'] as String? ??
                extra['otherUserAvatar'] as String? ??
                avatarUrl;
            if (extra['otherUserId'] != null) {
              otherUserId = extra['otherUserId'].toString();
            } else if (extra['callerId'] != null) {
              otherUserId = extra['callerId'].toString();
            } else if (extra['id'] != null) {
              otherUserId = extra['id'].toString();
            }
            if (extra['type'] != null) {
              type = extra['type'].toString();
            } else if (extra['callType'] != null) {
              type = extra['callType'].toString();
            }
            if (extra['callId'] != null) {
              callId = extra['callId'].toString();
            }
          }

          return PickupCallPage(
            callId: callId,
            otherUserId: otherUserId,
            contactName: name,
            avatarUrl: avatarUrl,
            callType: type,
          );
        },
      ),
    ],
  );
}

