import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../injection.dart';
import 'bloc/call_bloc.dart';

/// Screen displayed during an active or outgoing audio/video call.
/// Recreates the UI from on_call_page.png:
/// - Brand title 'Connect-Call' & subtitle 'Stay close, no matter the distance'
/// - Organic decorative wavy background accents
/// - Concentric glowing halos around contact avatar
/// - Contact name, 'In call' status, and live call timer
/// - Circular Mute toggle button
/// - Full-width red 'End Call' pill button
class OnCallPage extends StatefulWidget {
  const OnCallPage({
    super.key,
    this.otherUserId = 'cnt-1',
    this.contactName = 'Aditi Sharma',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    this.callType = 'audio',
    this.callBloc,
    this.onEndCall,
    this.onMuteToggled,
  });

  final String otherUserId;
  final String contactName;
  final String? avatarUrl;
  final String callType;
  final CallBloc? callBloc;
  final VoidCallback? onEndCall;
  final ValueChanged<bool>? onMuteToggled;

  @override
  State<OnCallPage> createState() => _OnCallPageState();
}

class _OnCallPageState extends State<OnCallPage> {
  CallBloc? _callBloc;
  bool _createdLocalBloc = false;
  bool _isMuted = false;
  Timer? _autoCloseTimer;
  bool _callInitiated = false;

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
      if (_callBloc?.state.isInitial ?? true) {
        _callBloc!.add(CallStartRequested(
          otherUserId: widget.otherUserId,
          otherUserName: widget.contactName,
          otherUserAvatar: widget.avatarUrl,
          type: widget.callType,
        ));
      }
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
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
      final audioTracks = callsService.localStream?.getAudioTracks();
      if (audioTracks != null) {
        for (final track in audioTracks) {
          track.enabled = !_isMuted;
        }
      }
    } catch (_) {}

    widget.onMuteToggled?.call(_isMuted);
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
            backgroundColor: const Color(0xFFFFFDF9),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final maxH = constraints.maxHeight;
                final contentWidth = maxW.clamp(300.0, 720.0);
                final horizontalPad = (maxW * 0.06).clamp(20.0, 36.0);

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

                        // 2. Foreground Main Content inside responsive scrollable viewport
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Brand Header
                                    _buildTopHeader(contentWidth),

                                    const SizedBox(height: 16),

                                    // Center Avatar with Glowing Halos & Details
                                    Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildAvatarWithHalos(
                                              contentWidth, maxH),
                                          const SizedBox(height: 20),
                                          _buildCallDetails(state),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Mute Button
                                    Center(
                                      child: _buildMuteButton(),
                                    ),

                                    const SizedBox(height: 24),

                                    // End Call Action Button
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
              },
            ),
          );
        },
      ),
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
          // Outer Glow Halo
          Container(
            width: outerHaloSize,
            height: outerHaloSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFBEADB),
            ),
          ),

          // Inner Glow Halo
          Container(
            width: innerHaloSize,
            height: innerHaloSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF9E4D0),
            ),
          ),

          // Contact Profile Photo with fallback
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
        // Contact Name
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

        // Call Status
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

        // Duration Counter
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

    // Top-Left Organic Shape
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

    // Bottom-Right Organic Shape
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
