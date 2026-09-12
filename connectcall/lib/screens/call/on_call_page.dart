import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

import '../../injection.dart';
import 'bloc/call_bloc.dart';

/// Screen displayed during an active or outgoing audio/video call.
/// Supports both:
/// 1. Audio Calls: Organic decorative background, concentric glowing halos around avatar, mute & end call.
/// 2. Video Calls:
///    - Full-screen remote video rendering via [RTCVideoRenderer] once status is ongoing.
///    - Floating local video preview in the right bottom corner.
///    - Modern control dock with Mute, Switch Camera (Rear/Front), Turn Off Camera, and End Call.
class OnCallPage extends StatefulWidget {
  const OnCallPage({
    super.key,
    this.otherUserId = 'cnt-1',
    this.contactName = 'Aditi Sharma',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    this.callType = 'audio',
    this.callId,
    this.isIncoming = false,
    this.callBloc,
    this.onEndCall,
    this.onMuteToggled,
    this.onCameraSwitched,
    this.onCameraToggled,
  });

  final String otherUserId;
  final String contactName;
  final String? avatarUrl;
  final String callType;
  final String? callId;
  final bool isIncoming;
  final CallBloc? callBloc;
  final VoidCallback? onEndCall;
  final ValueChanged<bool>? onMuteToggled;
  final VoidCallback? onCameraSwitched;
  final ValueChanged<bool>? onCameraToggled;

  @override
  State<OnCallPage> createState() => _OnCallPageState();
}

class _OnCallPageState extends State<OnCallPage> {
  CallBloc? _callBloc;
  bool _createdLocalBloc = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  Timer? _autoCloseTimer;
  bool _callInitiated = false;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isLocalRendererInitialized = false;
  bool _isRemoteRendererInitialized = false;
  StreamSubscription<MediaStream?>? _remoteStreamSubscription;
  StreamSubscription<MediaStream?>? _localStreamSubscription;

  bool get _isVideoCall {
    final fromWidget = widget.callType.trim().toLowerCase();
    final fromBloc = (_callBloc?.state.callType ?? '').trim().toLowerCase();
    return fromWidget == 'video' || fromBloc == 'video';
  }

  @override
  void initState() {
    super.initState();
    if (_isVideoCall) {
      _initRenderers();
    }
  }

  void _ensureRenderersInitialized() {
    if (_isVideoCall && !_isLocalRendererInitialized) {
      _initRenderers();
    }
  }

  Future<void> _initRenderers() async {
    try {
      await _localRenderer.initialize();
      _isLocalRendererInitialized = true;
    } catch (_) {}

    try {
      await _remoteRenderer.initialize();
      _isRemoteRendererInitialized = true;
    } catch (_) {}

    if (mounted) setState(() {});

    _attachStreams();

    try {
      _localStreamSubscription =
          callsService.onLocalStreamChange.listen((stream) {
        if (_isLocalRendererInitialized) {
          _localRenderer.srcObject = stream;
          if (mounted) setState(() {});
        }
      });
    } catch (_) {}

    try {
      _remoteStreamSubscription =
          callsService.onRemoteStreamChange.listen((stream) {
        if (_isRemoteRendererInitialized) {
          _remoteRenderer.srcObject = stream;
          if (mounted) setState(() {});
        }
      });
    } catch (_) {}
  }

  void _attachStreams() {
    if (!_isVideoCall) return;
    try {
      final localStream = callsService.localStream;
      if (_isLocalRendererInitialized &&
          localStream != null &&
          _localRenderer.srcObject != localStream) {
        _localRenderer.srcObject = localStream;
        if (mounted) setState(() {});
      }
      final remoteStream = callsService.remoteStream;
      if (_isRemoteRendererInitialized &&
          remoteStream != null &&
          _remoteRenderer.srcObject != remoteStream) {
        _remoteRenderer.srcObject = remoteStream;
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

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

    if (!_callInitiated) {
      _callInitiated = true;
      if (!widget.isIncoming && (_callBloc?.state.isInitial ?? true)) {
        _callBloc!.add(CallStartRequested(
          otherUserId: widget.otherUserId,
          otherUserName: widget.contactName,
          otherUserAvatar: widget.avatarUrl,
          type: widget.callType,
        ));
      } else if (widget.isIncoming) {
        if (_callBloc?.state.isIncoming ?? false) {
          _callBloc!.add(const CallPickUpRequested());
        } else if ((_callBloc?.state.isInitial ?? true) && widget.callId != null) {
          _callBloc!.add(CallIncomingReceived(
            callId: widget.callId!,
            callerId: widget.otherUserId,
            callerName: widget.contactName,
            callerAvatar: widget.avatarUrl,
            type: widget.callType,
          ));
          _callBloc!.add(const CallPickUpRequested());
        }
      }
    }

    _ensureRenderersInitialized();
    _attachStreams();
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _localStreamSubscription?.cancel();
    _remoteStreamSubscription?.cancel();
    if (_isVideoCall) {
      try {
        _localRenderer.dispose();
      } catch (_) {}
      try {
        _remoteRenderer.dispose();
      } catch (_) {}
    }
    if (_createdLocalBloc) {
      _callBloc?.close();
    } else if (!(_callBloc?.state.isActive ?? false)) {
      _callBloc?.add(const CallReset());
    }
    super.dispose();
  }

  void _handleToggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });

    try {
      callsService.toggleAudio(!_isMuted);
    } catch (_) {}

    widget.onMuteToggled?.call(_isMuted);
  }

  Future<void> _handleSwitchCamera() async {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    try {
      await callsService.switchCamera();
    } catch (_) {}

    widget.onCameraSwitched?.call();
  }

  void _handleToggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    try {
      callsService.toggleVideo(!_isCameraOff);
    } catch (_) {}

    widget.onCameraToggled?.call(_isCameraOff);
  }

  void _handleEndCall() {
    if (widget.onEndCall != null) {
      widget.onEndCall!();
    } else {
      _callBloc?.add(const CallEndRequested());
      _navigateBack();
    }
  }

  void _navigateBack() {
    if (!mounted) return;
    _autoCloseTimer?.cancel();
    _callBloc?.add(const CallReset());
    try {
      context.go('/home');
    } catch (_) {
      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _callBloc ?? (widget.callBloc ?? context.read<CallBloc>());
    return BlocProvider.value(
      value: bloc,
      child: BlocConsumer<CallBloc, CallState>(
        bloc: bloc,
        listener: (context, state) {
          _ensureRenderersInitialized();
          _attachStreams();
          if (state.isRejected) {
            _autoCloseTimer?.cancel();
            _navigateBack();
          } else if (state.isMissed || state.isEnded) {
            _autoCloseTimer?.cancel();
            _autoCloseTimer = Timer(const Duration(milliseconds: 1000), () {
              _navigateBack();
            });
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: _isVideoCall && state.isOngoing
                ? Colors.black
                : const Color(0xFFFFFDF9),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final maxH = constraints.maxHeight;
                final contentWidth = maxW.clamp(300.0, 720.0);
                final horizontalPad = (maxW * 0.06).clamp(20.0, 36.0);

                if (_isVideoCall && state.isOngoing) {
                  return _buildOngoingVideoLayout(
                    context,
                    state,
                    contentWidth,
                    maxH,
                    horizontalPad,
                  );
                }

                if (_isVideoCall) {
                  return _buildConnectingVideoLayout(
                    context,
                    state,
                    contentWidth,
                    maxH,
                    horizontalPad,
                  );
                }

                return _buildAudioCallLayout(
                  context,
                  state,
                  contentWidth,
                  maxH,
                  horizontalPad,
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Active ongoing video call layout:
  /// - Full-screen remote video stream via [RTCVideoRenderer]
  /// - Floating local video stream preview in bottom-right corner
  /// - Floating header with contact name & live timer
  /// - Bottom floating control dock (Mute, Flip, Cam Off, End)
  Widget _buildOngoingVideoLayout(
    BuildContext context,
    CallState state,
    double contentWidth,
    double maxH,
    double horizontalPad,
  ) {
    if (_isRemoteRendererInitialized &&
        _remoteRenderer.srcObject == null &&
        callsService.remoteStream != null) {
      _remoteRenderer.srcObject = callsService.remoteStream;
    }

    final hasRemoteVideo =
        _isRemoteRendererInitialized && _remoteRenderer.srcObject != null;

    return Center(
      child: SizedBox(
        width: contentWidth,
        height: maxH,
        child: Stack(
          children: [
            // 1. Remote Video Background
            Positioned.fill(
              key: const Key('remote_video_stream'),
              child: hasRemoteVideo
                  ? RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Container(
                      color: const Color(0xFF111827),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAvatarCircle(84),
                            const SizedBox(height: 14),
                            Text(
                              widget.contactName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Connected · Video active',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // 2. Subtle Dark Gradient Overlays for readability
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x99000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0xB3000000),
                      ],
                      stops: [0.0, 0.22, 0.72, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Top Floating Call Header
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              left: horizontalPad,
              right: horizontalPad,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.contactName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34C759),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.formattedDuration,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. Floating Local Video Stream Preview in Right Bottom Corner
            Positioned(
              key: const Key('local_video_stream'),
              right: horizontalPad,
              bottom: 114,
              child: _buildLocalVideoPreview(),
            ),

            // 5. Bottom Video Control Dock
            Positioned(
              left: horizontalPad,
              right: horizontalPad,
              bottom: (MediaQuery.paddingOf(context).bottom + 16).clamp(16.0, 48.0),
              child: Center(
                child: _buildVideoControlDock(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Connecting / Ringing video call layout:
  /// Retains the soft background and pulsing avatar, displays local video preview in bottom-right corner,
  /// and provides camera flip/mute/end options before connection.
  Widget _buildConnectingVideoLayout(
    BuildContext context,
    CallState state,
    double contentWidth,
    double maxH,
    double horizontalPad,
  ) {
    return Center(
      child: SizedBox(
        width: contentWidth,
        height: maxH,
        child: Stack(
          children: [
            // 1. Organic Decorative Background
            Positioned.fill(
              child: CustomPaint(
                painter: _OnCallBackgroundPainter(),
              ),
            ),

            // 2. Main Content
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPad,
                  vertical: 12.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(contentWidth),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isVideoCall) ...[
                            _buildVideoCallBadge(maxH),
                            const SizedBox(height: 14),
                          ],
                          _buildAvatarWithHalos(contentWidth, maxH),
                          const SizedBox(height: 20),
                          _buildCallDetails(state),
                        ],
                      ),
                    ),
                    Center(
                      child: _buildVideoControlDock(),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Local Video Preview in Right Bottom Corner
            Positioned(
              key: const Key('local_video_stream'),
              right: horizontalPad,
              bottom: 114,
              child: _buildLocalVideoPreview(),
            ),
          ],
        ),
      ),
    );
  }

  /// Audio call layout matching on_call_page.png
  Widget _buildAudioCallLayout(
    BuildContext context,
    CallState state,
    double contentWidth,
    double maxH,
    double horizontalPad,
  ) {
    return Center(
      child: SizedBox(
        width: contentWidth,
        height: maxH,
        child: Stack(
          children: [
            // 1. Organic Decorative Wave Background Accents
            Positioned.fill(
              child: CustomPaint(
                painter: _OnCallBackgroundPainter(),
              ),
            ),

            // 2. Foreground Main Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (maxH -
                            MediaQuery.paddingOf(context).top -
                            MediaQuery.paddingOf(context).bottom)
                        .clamp(0.0, double.infinity),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPad,
                      vertical: 12.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopHeader(contentWidth),
                        const SizedBox(height: 16),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAvatarWithHalos(contentWidth, maxH),
                              const SizedBox(height: 20),
                              _buildCallDetails(state),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: _buildMuteButton(),
                        ),
                        const SizedBox(height: 24),
                        _buildEndCallButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Floating local camera preview container in the right bottom corner.
  Widget _buildLocalVideoPreview() {
    if (_isLocalRendererInitialized &&
        _localRenderer.srcObject == null &&
        callsService.localStream != null) {
      _localRenderer.srcObject = callsService.localStream;
    }

    final hasLocalVideo = !_isCameraOff &&
        _isLocalRendererInitialized &&
        _localRenderer.srcObject != null;

    return Container(
      width: 110,
      height: 155,
      decoration: BoxDecoration(
        color: const Color(0xFF1E242E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasLocalVideo)
            RTCVideoView(
              _localRenderer,
              mirror: _isFrontCamera,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isCameraOff
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    color: Colors.white70,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isCameraOff ? 'Camera Off' : 'Your Video',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Video call floating control dock:
  /// [Mute] [Switch Camera] [Turn Off Camera] [End Call]
  Widget _buildVideoControlDock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E242E).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCircleActionButton(
            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: _isMuted ? 'Unmute' : 'Mute',
            isActive: _isMuted,
            activeColor: const Color(0xFFEA3829),
            onTap: _handleToggleMute,
          ),
          const SizedBox(width: 14),
          _buildCircleActionButton(
            icon: Icons.flip_camera_ios_rounded,
            label: 'Flip',
            isActive: false,
            onTap: _handleSwitchCamera,
          ),
          const SizedBox(width: 14),
          _buildCircleActionButton(
            icon: _isCameraOff
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            label: _isCameraOff ? 'Cam On' : 'Cam Off',
            isActive: _isCameraOff,
            activeColor: const Color(0xFFEA3829),
            onTap: _handleToggleCamera,
          ),
          const SizedBox(width: 14),
          _buildCircleActionButton(
            icon: Icons.call_end_rounded,
            label: 'End',
            isActive: true,
            activeColor: const Color(0xFFEA3829),
            bgColor: const Color(0xFFEA3829),
            iconColor: Colors.white,
            onTap: _handleEndCall,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    Color activeColor = const Color(0xFFFF6E00),
    Color? bgColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final effectiveBg = bgColor ??
        (isActive
            ? activeColor.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.12));
    final effectiveIconColor = iconColor ??
        (isActive ? activeColor : Colors.white);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: effectiveBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: effectiveIconColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle(double size) {
    final hasAvatar = widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFFFE8D6),
      backgroundImage: hasAvatar ? NetworkImage(widget.avatarUrl!) : null,
      onBackgroundImageError: hasAvatar ? (_, __) {} : null,
      child: !hasAvatar ? _buildInitialsFallback(size) : null,
    );
  }

  Widget _buildTopHeader(double maxWidth) {
    final titleFontSize = (maxWidth * 0.065).clamp(22.0, 27.0);
    final subtitleFontSize = (maxWidth * 0.035).clamp(12.5, 14.5);

    return Column(
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
    );
  }

  Widget _buildVideoCallBadge(double maxH) {
    final isCompact = maxH < 620;
    return Container(
      key: const Key('on_call_video_badge'),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0x1FFF6E00),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x66FF6E00),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18FF6E00),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_rounded,
              size: isCompact ? 16 : 18,
              color: const Color(0xFFFF6E00),
            ),
            const SizedBox(width: 6),
            Text(
              widget.isIncoming ? 'Incoming Video Call' : 'Video Call',
              style: TextStyle(
                color: const Color(0xFFFF6E00),
                fontSize: isCompact ? 12.0 : 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithHalos(double maxWidth, double maxHeight) {
    final outerHaloSize =
        (maxWidth * 0.70).clamp(180.0, (maxHeight * 0.35).clamp(180.0, 280.0));
    final innerHaloSize = outerHaloSize * 0.84;
    final avatarSize = outerHaloSize * 0.68;
    final hasAvatar = widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;

    return SizedBox(
      width: outerHaloSize,
      height: outerHaloSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: outerHaloSize,
            height: outerHaloSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFBEADB),
            ),
          ),
          Container(
            width: innerHaloSize,
            height: innerHaloSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF9E4D0),
            ),
          ),
          CircleAvatar(
            radius: avatarSize / 2,
            backgroundColor: const Color(0xFFFFE8D6),
            backgroundImage:
                hasAvatar ? NetworkImage(widget.avatarUrl!) : null,
            onBackgroundImageError: hasAvatar ? (_, __) {} : null,
            child: !hasAvatar ? _buildInitialsFallback(avatarSize) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsFallback(double avatarSize) {
    return Center(
      child: Text(
        widget.contactName.isNotEmpty
            ? widget.contactName[0].toUpperCase()
            : '?',
        style: TextStyle(
          color: const Color(0xFFFF6E00),
          fontSize: avatarSize * 0.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCallDetails(CallState state) {
    String statusText;
    String durationText;
    if (state.isOngoing) {
      statusText = 'Ongoing';
      durationText = state.formattedDuration;
    } else if (state.isRinging) {
      statusText = 'Ringing';
      durationText = state.formattedRingRemaining;
    } else if (state.isMissed) {
      statusText = 'Call Missed';
      durationText = '00:00';
    } else if (state.isEnded || state.isRejected) {
      statusText = 'Call Ended';
      durationText = state.formattedDuration;
    } else {
      statusText = 'Connecting...';
      durationText = '00:30';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.contactName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1E242E),
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          statusText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF757B88),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          durationText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 16.5,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildMuteButton() {
    return GestureDetector(
      onTap: _handleToggleMute,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF7ECE3),
            ),
            child: Icon(
              _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: const Color(0xFF2D3139),
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isMuted ? 'Unmute' : 'Mute',
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndCallButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _handleEndCall,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEA3829),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'End Call',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter rendering the organic wavy background corners matching on_call_page.png
class _OnCallBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFBEADB)
      ..style = PaintingStyle.fill;

    final topLeftPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.35, 0)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.08,
        size.width * 0.08,
        size.height * 0.12,
        0,
        size.height * 0.18,
      )
      ..close();
    canvas.drawPath(topLeftPath, paint);

    final bottomRightPath = Path()
      ..moveTo(size.width, size.height * 0.72)
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.78,
        size.width * 0.76,
        size.height * 0.90,
        size.width * 0.60,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(bottomRightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
