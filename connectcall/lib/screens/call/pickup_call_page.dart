import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../injection.dart';
import 'bloc/call_bloc.dart';

/// Screen displayed when the user receives an incoming audio or video call.
/// Recreates the UI from pickup-call-page.png:
/// - Brand header 'Connect-Call' & subtitle 'Stay close, no matter the distance'
/// - Organic decorative wavy background accents in top-left and bottom-right corners
/// - Concentric glowing halos around the caller's avatar
/// - Caller name and 'Incoming call...' subtitle
/// - Red circular 'End' action button with soft red glow
/// - Orange circular 'Pick Up' action button with soft orange glow
/// - BLoC integration handling call acceptance (redirecting to OnCallPage) and rejection
class PickupCallPage extends StatefulWidget {
  const PickupCallPage({
    super.key,
    this.callId,
    this.otherUserId = 'cnt-1',
    this.contactName = 'Aditi Sharma',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    this.callType = 'audio',
    this.callBloc,
    this.onPickUp,
    this.onEnd,
  });

  /// Firestore call ID if available.
  final String? callId;

  /// User ID of the caller.
  final String otherUserId;

  /// Display name of the caller.
  final String contactName;

  /// Profile avatar URL of the caller.
  final String? avatarUrl;

  /// Call type: 'audio' or 'video'.
  final String callType;

  /// Optional injected [CallBloc] for dependency injection and testing.
  final CallBloc? callBloc;

  /// Callback when Pick Up is tapped.
  final VoidCallback? onPickUp;

  /// Callback when End is tapped.
  final VoidCallback? onEnd;

  @override
  State<PickupCallPage> createState() => _PickupCallPageState();
}

class _PickupCallPageState extends State<PickupCallPage> {
  CallBloc? _callBloc;
  bool _createdLocalBloc = false;
  bool _redirected = false;

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

      // If call state is not already incoming or active, initialize it as incoming
      if (!(_callBloc?.state.isActive ?? false)) {
        _callBloc?.add(CallIncomingReceived(
          callId: widget.callId ?? 'call_${DateTime.now().millisecondsSinceEpoch}',
          callerId: widget.otherUserId,
          callerName: widget.contactName,
          callerAvatar: widget.avatarUrl,
          type: widget.callType,
        ));
      }
    }
  }

  @override
  void dispose() {
    if (_createdLocalBloc) {
      _callBloc?.close();
    }
    super.dispose();
  }

  void _handlePickUp() {
    if (_redirected) return;
    _redirected = true;

    widget.onPickUp?.call();
    _callBloc?.add(const CallPickUpRequested());

    _redirectToOnCall();
  }

  void _handleEnd() {
    if (_redirected) return;
    _redirected = true;

    widget.onEnd?.call();
    _callBloc?.add(const CallRejectRequested());

    _dismissPage();
  }

  void _redirectToOnCall() {
    if (!mounted) return;
    try {
      context.pushReplacement('/on-call', extra: {
        'otherUserId': widget.otherUserId,
        'otherUserName': widget.contactName,
        'otherUserAvatar': widget.avatarUrl,
        'callType': widget.callType,
        'callId': widget.callId ?? _callBloc?.state.callId,
      });
    } catch (_) {
      try {
        Navigator.of(context).pushReplacementNamed('/on-call');
      } catch (_) {}
    }
  }

  void _dismissPage() {
    if (!mounted) return;
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
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
    final effectiveBloc = _callBloc ??
        widget.callBloc ??
        (getIt.isRegistered<CallBloc>() ? callBloc : CallBloc());

    return BlocProvider<CallBloc>.value(
      value: effectiveBloc,
      child: BlocConsumer<CallBloc, CallState>(
        bloc: effectiveBloc,
        listener: (context, state) {
          if (state.isOngoing && !_redirected) {
            _redirected = true;
            _redirectToOnCall();
          } else if ((state.isMissed || state.isRejected || state.isEnded) &&
              !_redirected) {
            _redirected = true;
            _dismissPage();
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFFFF9F2),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final maxH = constraints.maxHeight;

                final contentWidth = maxW.clamp(300.0, 720.0);
                final horizontalPadding = (maxW * 0.06).clamp(20.0, 36.0);
                final topSpacing = (maxH * 0.05).clamp(24.0, 50.0);
                final titleFontSize = (maxW * 0.068).clamp(24.0, 30.0);
                final subtitleFontSize = (maxW * 0.035).clamp(12.5, 15.0);
                final nameFontSize = (maxW * 0.068).clamp(24.0, 30.0);
                final statusFontSize = (maxW * 0.038).clamp(14.0, 16.5);
                final buttonSize = (maxW * 0.20).clamp(72.0, 84.0);
                final actionIconSize = (buttonSize * 0.46).clamp(32.0, 38.0);
                final labelFontSize = (maxW * 0.040).clamp(14.5, 16.5);

                return Stack(
                  children: [
                    // 1. Organic Decorative Background Accents
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PickupCallBackgroundPainter(),
                      ),
                    ),

                    // 2. Main Content
                    SafeArea(
                      child: Center(
                        child: SizedBox(
                          width: contentWidth,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: topSpacing),

                                // Brand Title: Connect-Call
                                _buildHeader(titleFontSize, subtitleFontSize),

                                const Spacer(flex: 2),

                                // Caller Avatar with Concentric Halos
                                _buildAvatarWithHalos(maxW, maxH),

                                const SizedBox(height: 24),

                                // Caller Name & Incoming Call Subtitle
                                Text(
                                  widget.contactName,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color(0xFF1E242E),
                                    fontSize: nameFontSize,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Incoming call...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF757B88),
                                    fontSize: statusFontSize,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.1,
                                  ),
                                ),

                                const Spacer(flex: 3),

                                // Bottom Action Buttons: End & Pick Up
                                _buildActionButtons(
                                  buttonSize: buttonSize,
                                  iconSize: actionIconSize,
                                  labelFontSize: labelFontSize,
                                ),

                                SizedBox(height: (maxH * 0.07).clamp(32.0, 60.0)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(double titleFontSize, double subtitleFontSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
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
        const SizedBox(height: 4),
        Text(
          'Stay close, no matter the distance',
          textAlign: TextAlign.center,
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
        (maxWidth * 0.72).clamp(190.0, (maxHeight * 0.36).clamp(190.0, 280.0));
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

          // Caller Avatar Photo with fallback initials
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
          fontSize: avatarSize * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionButtons({
    required double buttonSize,
    required double iconSize,
    required double labelFontSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // End Call Button (Red with drop shadow)
        _buildActionButton(
          key: const Key('pickup_end_button'),
          label: 'End',
          color: const Color(0xFFFF3B30),
          shadowColor: const Color(0x55FF3B30),
          icon: Icons.call_end_rounded,
          buttonSize: buttonSize,
          iconSize: iconSize,
          labelFontSize: labelFontSize,
          onTap: _handleEnd,
        ),

        // Pick Up Call Button (Orange with drop shadow)
        _buildActionButton(
          key: const Key('pickup_accept_button'),
          label: 'Pick Up',
          color: const Color(0xFFFF6E00),
          shadowColor: const Color(0x55FF6E00),
          icon: Icons.call_rounded,
          buttonSize: buttonSize,
          iconSize: iconSize,
          labelFontSize: labelFontSize,
          onTap: _handlePickUp,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required Key key,
    required String label,
    required Color color,
    required Color shadowColor,
    required IconData icon,
    required double buttonSize,
    required double iconSize,
    required double labelFontSize,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 22,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: key,
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF1E242E),
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

/// Custom painter rendering organic fluid curved accents in corners matching pickup-call-page.png
class _PickupCallBackgroundPainter extends CustomPainter {
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
