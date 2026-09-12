import 'package:flutter/material.dart';

import '../../../injection.dart';
import '../../../services/firebase/session.service.dart';
import '../models/call_log_model.dart';

/// Single call log item matching the row style in homepage.png.
class CallLogItem extends StatelessWidget {
  const CallLogItem({
    super.key,
    required this.call,
    required this.maxWidth,
    this.currentUserId,
    this.onTap,
    this.onCallTap,
  });

  final CallLogModel call;
  final double maxWidth;
  final String? currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onCallTap;

  @override
  Widget build(BuildContext context) {
    // Clamped responsive values
    final avatarRadius = (maxWidth * 0.065).clamp(22.0, 27.0);
    final nameFontSize = (maxWidth * 0.040).clamp(14.5, 16.5);
    final subtitleFontSize = (maxWidth * 0.033).clamp(12.0, 13.5);
    final dateTimeFontSize = (maxWidth * 0.030).clamp(11.0, 12.5);
    final actionIconSize = (maxWidth * 0.055).clamp(20.0, 24.0);

    final resolvedUserId = currentUserId ??
        (getIt.isRegistered<SessionService>()
            ? sessionService.currentUser?.uid
            : null);
    final callerId = call.callerId ?? call.callModel?.callerId;

    final bool isCaller;
    if (resolvedUserId != null &&
        resolvedUserId.isNotEmpty &&
        callerId != null &&
        callerId.isNotEmpty) {
      isCaller = (resolvedUserId == callerId);
    } else {
      isCaller = (call.callType == CallType.outgoing);
    }

    // Tilted upper arrow for missed, outgoing, or ended when current user is caller.
    // Tilted down arrow for incoming cases.
    final directionIcon = isCaller
        ? Icons.north_east_rounded
        : Icons.south_west_rounded;

    final isMissed = call.callType == CallType.missed ||
        (call.callModel?.isMissed ?? false);

    final directionColor = isMissed
        ? const Color(0xFFE53935)
        : const Color(0xFFFF6E00);
    final hasAvatar = call.avatarUrl != null && call.avatarUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            // Circular Avatar with Live Online/Offline Status Indicator Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: const Color(0xFFFFE8D6),
                  backgroundImage: hasAvatar ? NetworkImage(call.avatarUrl!) : null,
                  onBackgroundImageError: hasAvatar ? (_, __) {} : null,
                  child: !hasAvatar
                      ? Text(
                          call.name.isNotEmpty ? call.name[0] : '?',
                          style: TextStyle(
                            color: const Color(0xFFFF6E00),
                            fontSize: avatarRadius * 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: (avatarRadius * 0.48).clamp(10.0, 13.0),
                    height: (avatarRadius * 0.48).clamp(10.0, 13.0),
                    decoration: BoxDecoration(
                      color: call.isOnline
                          ? const Color(0xFF34C759)
                          : const Color(0xFFB0B5BF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFFDF9),
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Name & Status Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    call.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF1E242E),
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        directionIcon,
                        size: (subtitleFontSize * 1.1).clamp(13.0, 15.0),
                        color: directionColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          call.timeSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isMissed
                                ? const Color(0xFFE53935)
                                : const Color(0xFF757B88),
                            fontSize: subtitleFontSize,
                            fontWeight: isMissed
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Date, Time & Action Button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      call.date,
                      style: TextStyle(
                        color: const Color(0xFF757B88),
                        fontSize: dateTimeFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      call.time,
                      style: TextStyle(
                        color: const Color(0xFF757B88),
                        fontSize: dateTimeFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                IconButton(
                  onPressed: onCallTap,
                  icon: Icon(
                    call.mediaType == CallMediaType.video
                        ? Icons.videocam_rounded
                        : Icons.phone_rounded,
                    color: const Color(0xFFFF6E00),
                    size: actionIconSize,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  splashRadius: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
