import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/app_header.dart';
import '../../contacts/models/contact_model.dart';
import '../../contacts/widgets/contact_list_item.dart';
import '../../home/widgets/home_search_bar.dart';

/// Background view behind the MakeCall bottom card, showing the AppHeader,
/// search bar, contacts list, and a subtle dimmed overlay.
class MakeCallBackground extends StatelessWidget {
  const MakeCallBackground({
    super.key,
    required this.contentWidth,
    required this.horizontalPadding,
    required this.onSignOut,
    required this.onOverlayTap,
  });

  final double contentWidth;
  final double horizontalPadding;
  final VoidCallback onSignOut;
  final VoidCallback onOverlayTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Content: AppHeader + Search + Contacts List
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12.0,
                  horizontalPadding,
                  0.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHeader(
                      maxWidth: contentWidth,
                      onSignOut: onSignOut,
                      action: InkWell(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/contacts');
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 4.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                                color: Color(0xFF1E242E),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Contacts',
                                style: TextStyle(
                                  color: Color(0xFF1E242E),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    HomeSearchBar(
                      maxWidth: contentWidth,
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Contact items behind the bottom sheet
              Expanded(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    0.0,
                    horizontalPadding,
                    0.0,
                  ),
                  itemCount: ContactModel.sampleContacts.length,
                  itemBuilder: (context, index) {
                    final contact = ContactModel.sampleContacts[index];
                    return ContactListItem(
                      contact: contact,
                      maxWidth: contentWidth,
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // 2. Dimmed Overlay (Subtle scrim above background)
        Positioned.fill(
          child: GestureDetector(
            onTap: onOverlayTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ),
        ),
      ],
    );
  }
}
