import 'package:flutter/material.dart';

import '../models/contact_model.dart';

/// Single contact row item matching contact page.png design.
class ContactListItem extends StatelessWidget {
  const ContactListItem({
    super.key,
    required this.contact,
    required this.maxWidth,
    this.onTap,
  });

  final ContactModel contact;
  final double maxWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarRadius = (maxWidth * 0.062).clamp(22.0, 26.0);
    final nameFontSize = (maxWidth * 0.042).clamp(15.0, 16.5);
    final avatarDiameter = avatarRadius * 2;
    final hasAvatar =
        contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9.0),
            child: Row(
              children: [
                // Circular Avatar
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: const Color(0xFFFFE8D6),
                  backgroundImage:
                      hasAvatar ? NetworkImage(contact.avatarUrl!) : null,
                  onBackgroundImageError: hasAvatar ? (_, __) {} : null,
                  child: !hasAvatar
                      ? (contact.isGroup
                          ? Icon(
                              Icons.groups_rounded,
                              color: const Color(0xFFFF6E00),
                              size: avatarRadius * 1.1,
                            )
                          : Text(
                              contact.name.isNotEmpty ? contact.name[0] : '?',
                              style: TextStyle(
                                color: const Color(0xFFFF6E00),
                                fontSize: avatarRadius * 0.85,
                                fontWeight: FontWeight.w700,
                              ),
                            ))
                      : null,
                ),
                const SizedBox(width: 16),

                // Contact Name
                Expanded(
                  child: Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF1E242E),
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Hairline divider starting after the avatar
          Padding(
            padding: EdgeInsets.only(left: avatarDiameter + 16),
            child: const Divider(
              height: 1,
              thickness: 0.8,
              color: Color(0xFFF2ECE5),
            ),
          ),
        ],
      ),
    );
  }
}
