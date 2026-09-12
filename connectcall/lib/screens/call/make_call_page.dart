import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../injection.dart';
import 'bloc/call_bloc.dart';
import 'widgets/make_call_background.dart';
import 'widgets/make_call_bottom_sheet.dart';

class MakeCallPage extends StatefulWidget {
  const MakeCallPage({
    super.key,
    this.otherUserId = '',
    this.contactName = '',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    this.isOnline = true,
    this.autoStart = false,
    this.callType = 'audio',
    this.callBloc,
    this.onAudioCall,
    this.onVideoCall,
    this.onClose,
  });

  /// The unique identifier of the contact being called.
  final String otherUserId;

  /// Name of the contact to call.
  final String contactName;

  /// Profile avatar URL of the contact.
  final String? avatarUrl;

  /// Whether the contact is currently online.
  final bool isOnline;

  /// Whether to automatically initiate the call upon navigating to this page.
  final bool autoStart;

  /// Call type for autoStart: 'audio' or 'video'.
  final String callType;

  /// Optional injected [CallBloc]. If omitted, one is retrieved or created.
  final CallBloc? callBloc;

  /// Callback when the Audio Call button is tapped.
  final VoidCallback? onAudioCall;

  /// Callback when the Video Call button is tapped.
  final VoidCallback? onVideoCall;

  /// Callback when the Close button is tapped.
  final VoidCallback? onClose;

  @override
  State<MakeCallPage> createState() => _MakeCallPageState();
}

class _MakeCallPageState extends State<MakeCallPage> {
  CallBloc? _callBloc;
  bool _createdLocalBloc = false;
  bool _autoStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_callBloc == null) {
      if (widget.callBloc != null) {
        _callBloc = widget.callBloc!;
        _createdLocalBloc = false;
      } else {
        try {
          _callBloc = context.read<CallBloc>();
          _createdLocalBloc = false;
        } catch (_) {
          try {
            _callBloc = callBloc;
          } catch (_) {
            _callBloc = CallBloc();
          }
          _createdLocalBloc = true;
        }
      }
    }

    if (widget.autoStart && !_autoStarted && !(_callBloc?.state.isActive ?? false)) {
      _autoStarted = true;
      _callBloc?.add(CallStartRequested(
        otherUserId: widget.otherUserId,
        otherUserName: widget.contactName,
        otherUserAvatar: widget.avatarUrl,
        type: widget.callType,
      ));
    }
  }

  @override
  void dispose() {
    if (_createdLocalBloc) {
      _callBloc?.close();
    }
    super.dispose();
  }

  void _handleAudioCall() {
    if (widget.onAudioCall != null) {
      widget.onAudioCall!();
    } else {
      _callBloc?.add(CallStartRequested(
        otherUserId: widget.otherUserId,
        otherUserName: widget.contactName,
        otherUserAvatar: widget.avatarUrl,
        type: 'audio',
      ));
    }
  }

  void _handleVideoCall() {
    if (widget.onVideoCall != null) {
      widget.onVideoCall!();
    } else {
      _callBloc?.add(CallStartRequested(
        otherUserId: widget.otherUserId,
        otherUserName: widget.contactName,
        otherUserAvatar: widget.avatarUrl,
        type: 'video',
      ));
    }
  }

  void _handleClose(BuildContext context) {
    if (_callBloc?.state.isActive ?? false) {
      _callBloc?.add(const CallEndRequested());
    }
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    await sessionService.signOut();
    if (context.mounted) {
      try {
        appRouter.router.go('/login');
      } catch (_) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _callBloc ?? (widget.callBloc ?? context.read<CallBloc>());
    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFDF9),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;

            final horizontalPadding = (maxW * 0.045).clamp(16.0, 32.0);
            final contentWidth = maxW.clamp(300.0, 720.0);

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: maxH,
                child: Stack(
                  children: [
                    // 1. Background Screen: Header, search, contacts list, dimmed scrim
                    Positioned.fill(
                      child: MakeCallBackground(
                        contentWidth: contentWidth,
                        horizontalPadding: horizontalPadding,
                        onSignOut: () => _handleSignOut(context),
                        onOverlayTap: () => _handleClose(context),
                      ),
                    ),

                    // 2. Foreground: MakeCall Bottom Sheet Card
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: BlocConsumer<CallBloc, CallState>(
                        listener: (context, state) {
                          if (state.isRinging || state.isOngoing) {
                            // On caller side if the call state is ringing or ongoing redirect to on call page
                            context.pushReplacement('/on-call', extra: {
                              'otherUserId': widget.otherUserId,
                              'otherUserName': widget.contactName,
                              'otherUserAvatar': widget.avatarUrl,
                              'callType': state.callType,
                              'callId': state.callId,
                            });
                          } else if (state.isRejected) {
                            // And if rejected redirect to home page and dispose all the call state data
                            _callBloc?.add(const CallReset());
                            context.go('/home');
                          } else if (state.isMissed) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No answer. Call marked as missed.'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            _callBloc?.add(const CallReset());
                            context.go('/home');
                          } else if (state.isEnded) {
                            _callBloc?.add(const CallReset());
                            context.go('/home');
                          }
                        },
                        builder: (context, state) {
                          return Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              MakeCallBottomSheet(
                                contentWidth: contentWidth,
                                horizontalPadding: horizontalPadding,
                                contactName: widget.contactName,
                                avatarUrl: widget.avatarUrl,
                                isOnline: widget.isOnline,
                                onClose: () => _handleClose(context),
                                onAudioCall: _handleAudioCall,
                                onVideoCall: _handleVideoCall,
                              ),
                              if (state.isActive || state.isMissed || state.isEnded)
                                Positioned(
                                  top: 16,
                                  child: _CallStatusBadge(
                                    state: state,
                                    onEndCall: () => _callBloc?.add(const CallEndRequested()),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CallStatusBadge extends StatelessWidget {
  const _CallStatusBadge({
    required this.state,
    required this.onEndCall,
  });

  final CallState state;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFFF6E00);
    String label = 'Calling...';

    if (state.isRinging) {
      bg = const Color(0xFFFF9500);
      label = 'Ringing (${state.ringRemainingSeconds}s)';
    } else if (state.isOngoing) {
      bg = const Color(0xFF34C759);
      label = 'Connected · ${state.formattedDuration}';
    } else if (state.isMissed) {
      bg = const Color(0xFFFF3B30);
      label = 'Missed Call';
    } else if (state.isEnded) {
      bg = const Color(0xFF8E8E93);
      label = 'Call Ended · ${state.formattedDuration}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (state.isActive) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onEndCall,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
