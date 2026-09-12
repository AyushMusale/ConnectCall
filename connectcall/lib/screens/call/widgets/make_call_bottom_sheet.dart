import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'call_action_card.dart';

/// Floating bottom card container displaying the contact avatar, name, online status,
/// Close button, and Audio/Video call action cards matching makeCall_page.png.
class MakeCallBottomSheet extends StatelessWidget {
  const MakeCallBottomSheet({
    super.key,
    this.contentWidth,
    this.horizontalPadding,
    required this.contactName,
    this.avatarUrl,
    this.isOnline = true,
    this.onClose,
    this.onAudioCall,
    this.onVideoCall,
  });

  /// Optional fixed width. If omitted, clamps to responsive width (300 to 720).
  final double? contentWidth;

  /// Optional horizontal padding. If omitted, computes from width.
  final double? horizontalPadding;

  /// Name of the contact to call.
  final String contactName;

  /// Profile avatar URL of the contact.
  final String? avatarUrl;

  /// Whether the contact is currently online.
  final bool isOnline;

  /// Callback when the Close button is tapped.
  final VoidCallback? onClose;

  /// Callback when the Audio Call button is tapped.
  final VoidCallback? onAudioCall;

  /// Callback when the Video Call button is tapped.
  final VoidCallback? onVideoCall;

  /// Displays [MakeCallBottomSheet] directly as a modal bottom sheet
  /// over the current page without redirecting.
  static Future<void> show(
    BuildContext context, {
    required String contactName,
    String? avatarUrl,
    bool isOnline = true,
    VoidCallback? onAudioCall,
    VoidCallback? onVideoCall,
    VoidCallback? onClose,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      builder: (sheetContext) => MakeCallBottomSheet(
        contactName: contactName,
        avatarUrl: avatarUrl,
        isOnline: isOnline,
        onClose: () {
          if (onClose != null) {
            onClose();
          } else {
            Navigator.of(sheetContext).pop();
          }
        },
        onAudioCall: onAudioCall,
        onVideoCall: onVideoCall,
      ),
    );
  }

  void _handleClose(BuildContext context) {
    if (onClose != null) {
      onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final width = contentWidth ?? screenW.clamp(300.0, 720.0);
    final pad = horizontalPadding ?? (width * 0.045).clamp(16.0, 32.0);
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    final avatarRadius = (width * 0.14).clamp(46.0, 58.0);
    final nameFontSize = (width * 0.052).clamp(19.0, 22.5);
    final actionCardHeight = (width * 0.22).clamp(86.0, 104.0);
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: width,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 28.0,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              pad,
              12.0,
              pad,
              bottomSafeArea > 0 ? 12.0 : 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Bar: Drag Handle Pill in center, Close button on right
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Drag Handle Pill
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4D4D8),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),

                    // Top Right Close Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => _handleClose(context),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 6.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Close',
                                style: TextStyle(
                                  color: Color(0xFF525866),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.close_rounded,
                                size: 19,
                                color: Color(0xFF525866),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Large Contact Avatar
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: const Color(0xFFFFE8D6),
                  backgroundImage:
                      hasAvatar ? NetworkImage(avatarUrl!) : null,
                  onBackgroundImageError:
                      hasAvatar ? (_, __) {} : null,
                  child: !hasAvatar
                      ? Text(
                          contactName.isNotEmpty
                              ? contactName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: const Color(0xFFFF6E00),
                            fontSize: avatarRadius * 0.9,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 14),

                // Contact Name
                Text(
                  contactName,
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
                const SizedBox(height: 5),

                // Online Indicator & Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF34C759)
                            : const Color(0xFF9E9E9E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Color(0xFF757B88),
                        fontSize: 14.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Cards: Audio Call & Video Call
                Row(
                  children: [
                    // 1. Audio Call Card
                    Expanded(
                      child: CallActionCard(
                        height: actionCardHeight,
                        icon: Icons.call_rounded,
                        iconSize: (width * 0.075).clamp(26.0, 32.0),
                        label: 'Audio Call',
                        onTap: () {
                          if (onAudioCall != null) {
                            onAudioCall!();
                          } else {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                            context.push('/on-call', extra: {
                              'otherUserId': 'cnt-1',
                              'otherUserName': contactName,
                              'otherUserAvatar': avatarUrl,
                              'type': 'audio',
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),

                    // 2. Video Call Card
                    Expanded(
                      child: CallActionCard(
                        height: actionCardHeight,
                        icon: Icons.videocam_rounded,
                        iconSize: (width * 0.085).clamp(28.0, 36.0),
                        label: 'Video Call',
                        onTap: () {
                          if (onVideoCall != null) {
                            onVideoCall!();
                          } else {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                            context.push('/on-call', extra: {
                              'otherUserId': 'cnt-1',
                              'otherUserName': contactName,
                              'otherUserAvatar': avatarUrl,
                              'type': 'video',
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
