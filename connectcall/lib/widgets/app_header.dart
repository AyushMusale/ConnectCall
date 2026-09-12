import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../injection.dart';
import '../screens/auth/bloc/auth_bloc.dart';
import '../screens/call/bloc/call_bloc.dart';
import '../services/firebase/signaling.service.dart';

/// App-wide top header displaying the ConnectCall brand title, tagline,
/// and three-dots overflow menu with Sign Out.
///
/// Continuously listens for incoming calls. When status is 'ringing',
/// renders the pickup call page (`/pickup-call`). Once the state changes
/// (ended, rejected, missed), renders the home page (`/home`).
class AppHeader extends StatefulWidget {
  const AppHeader({
    super.key,
    required this.maxWidth,
    this.onSignOut,
    this.action,
    this.signalingService,
  });

  final double maxWidth;
  final VoidCallback? onSignOut;
  final Widget? action;
  final SignalingService? signalingService;

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  StreamSubscription<dynamic>? _incomingCallSubscription;
  StreamSubscription<dynamic>? _callStatusSubscription;
  Timer? _incomingTimeoutTimer;
  String? _currentRingingCallId;

  @override
  void initState() {
    super.initState();
    _startIncomingCallListener();
  }

  void _startIncomingCallListener() {
    // Trigger CallBloc listener event if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<CallBloc>().add(const CallIncomingListenerStarted());
        } catch (_) {}
      }
    });

    final service = widget.signalingService ??
        (Firebase.apps.isNotEmpty ? signalingService : null);

    // Continuously listen for incoming calls if signaling service is available
    if (service != null) {
      try {
        _incomingCallSubscription?.cancel();
        _incomingCallSubscription = service.listenForIncomingCalls(
          onIncomingCall: (callDoc) {
            final data = callDoc.data();
            if (data == null) return;
            final status =
                (data['status'] ?? 'ringing').toString().toLowerCase();

            // If the status is ringing, render the pickup call page
            if (status == 'ringing') {
              final callId = callDoc.id;
              if (_currentRingingCallId == callId) {
                return;
              }
              _currentRingingCallId = callId;

              final callerId = (data['callerId'] ?? '').toString();
              final callerName = (data['callerName'] ?? 'Contact').toString();
              final callerAvatar = data['callerAvatar'] as String?;
              final type = (data['type'] ?? 'audio').toString();

              if (mounted) {
                try {
                  context.read<CallBloc>().add(CallIncomingReceived(
                        callId: callId,
                        callerId: callerId,
                        callerName: callerName,
                        callerAvatar: callerAvatar,
                        type: type,
                      ));
                } catch (_) {}

                context.push('/pickup-call', extra: {
                  'callId': callId,
                  'callerId': callerId,
                  'name': callerName,
                  'avatarUrl': callerAvatar,
                  'type': type,
                });

                // 30 seconds timer: keep page open till 30 seconds then close
                _incomingTimeoutTimer?.cancel();
                _incomingTimeoutTimer = Timer(const Duration(seconds: 30), () {
                  _callStatusSubscription?.cancel();
                  _callStatusSubscription = null;
                  _currentRingingCallId = null;
                  if (mounted) {
                    context.go('/home');
                  }
                });

                // Once the state changes, render the home page
                _callStatusSubscription?.cancel();
                _callStatusSubscription = service.listenToCall(
                  callId: callId,
                  onStatusChanged: (newStatus) {
                    final s = newStatus.toLowerCase();
                    if (s == 'ongoing') {
                      _incomingTimeoutTimer?.cancel();
                      _callStatusSubscription?.cancel();
                      _callStatusSubscription = null;
                      _currentRingingCallId = null;
                      // Answered: handled by PickUp -> /on-call
                    } else if (s == 'rejected' || s == 'missed') {
                      _incomingTimeoutTimer?.cancel();
                      _callStatusSubscription?.cancel();
                      _callStatusSubscription = null;
                      _currentRingingCallId = null;
                      if (mounted) {
                        context.go('/home');
                      }
                    }
                    // For 'ended', keep page open till 30 seconds then close via timeout
                  },
                );
              }
            }
          },
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    _callStatusSubscription?.cancel();
    _incomingTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsiveness using clamp
    final titleFontSize = (widget.maxWidth * 0.065).clamp(20.0, 26.0);
    final subtitleFontSize = (widget.maxWidth * 0.035).clamp(12.0, 14.5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Title & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Connect',
                  style: TextStyle(
                    color: const Color(0xFF1E242E),
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(
                      text: '-Call',
                      style: TextStyle(
                        color: const Color(0xFFFF6E00),
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Stay close, no matter the distance',
                style: TextStyle(
                  color: const Color(0xFF757B88),
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),

        // Optional Action
        if (widget.action != null) widget.action!,

        // Overflow Menu (Three Dots) Button
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: Color(0xFF1E242E),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          splashRadius: 20,
          tooltip: 'More options',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          elevation: 4,
          onSelected: (value) async {
            if (value == 'signout') {
              if (widget.onSignOut != null) {
                widget.onSignOut!();
              } else {
                await sessionService.signOut();
                if (context.mounted) {
                  try {
                    context.read<AuthBloc>().add(const AuthResetState());
                  } catch (_) {}
                  context.go('/login');
                }
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'signout',
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE53935),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Type alias maintaining backward compatibility for [HomeHeader].
typedef HomeHeader = AppHeader;
