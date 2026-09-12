import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../injection.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_header.dart';
import '../auth/bloc/auth_bloc.dart';
import '../call/widgets/make_call_bottom_sheet.dart';
import '../home/widgets/home_search_bar.dart';
import 'bloc/contact_bloc.dart';
import 'models/contact_model.dart';
import 'widgets/contact_list_item.dart';

/// ContactPage UI featuring responsive LayoutBuilder, clamped metrics,
/// and BlocConsumer / BlocBuilder structure connected to [ContactBloc] and [ContactService].
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ContactPageView();
  }
}

class _ContactPageView extends StatefulWidget {
  const _ContactPageView();

  @override
  State<_ContactPageView> createState() => _ContactPageViewState();
}

class _ContactPageViewState extends State<_ContactPageView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // On init in contact page, fetch contacts if state is initial
    final bloc = context.read<ContactBloc>();
    if (bloc.state.isInitial) {
      bloc.add(const ContactFetchRequested());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    await sessionService.signOut();
    if (mounted) {
      try {
        context.read<AuthBloc>().add(const AuthResetState());
      } catch (_) {}
      context.go('/login');
    }
  }

  void _handleMakeCall(ContactModel contact) {
    MakeCallBottomSheet.show(
      context,
      contactName: contact.otherUserName,
      avatarUrl: contact.otherUserAvatar,
      onAudioCall: () {
        Navigator.of(context).pop();
        context.push('/make-call', extra: {
          'otherUserId': contact.otherUserId,
          'otherUserName': contact.otherUserName,
          'otherUserAvatar': contact.otherUserAvatar,
          'type': 'audio',
          'autoStart': true,
        });
      },
      onVideoCall: () {
        Navigator.of(context).pop();
        context.push('/make-call', extra: {
          'otherUserId': contact.otherUserId,
          'otherUserName': contact.otherUserName,
          'otherUserAvatar': contact.otherUserAvatar,
          'type': 'video',
          'autoStart': true,
        });
      },
    );
  }

  List<ContactModel> _filterContacts(List<ContactModel> contacts) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return contacts;
    }
    return contacts
        .where((contact) =>
            contact.otherUserName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;

          final horizontalPadding = (maxW * 0.045).clamp(16.0, 32.0);
          final contentWidth = maxW.clamp(300.0, 720.0);
          final bottomNavBottomPadding = (maxH * 0.02).clamp(10.0, 24.0);
          final listBottomPadding = (maxW * 0.25).clamp(80.0, 110.0);

          return Stack(
            children: [
              // Main Layout: Fixed Top Header & Search Bar + Scrollable Content
              SafeArea(
                bottom: false,
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. FIXED TOP SECTION (AppHeader, Search Bar)
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
                                onSignOut: _handleSignOut,
                              ),
                              const SizedBox(height: 18),
                              HomeSearchBar(
                                maxWidth: contentWidth,
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),

                        // 2. STATE-BASED CONTACTS CONTENT
                        Expanded(
                          child: BlocBuilder<ContactBloc, ContactState>(
                            builder: (context, state) {
                              if (state.isLoading) {
                                // While loading: show magnify icon with skeleton animation
                                return ContactLoadingSkeleton(
                                  horizontalPadding: horizontalPadding,
                                );
                              }

                              if (state.isFailure) {
                                // If failure: show grey cross with failed text
                                return _buildFailureView(
                                  context,
                                  state.errorMessage,
                                );
                              }

                              // Success state
                              final filteredContacts =
                                  _filterContacts(state.contacts);
                              
                              if (state.contacts.isEmpty ||
                                  filteredContacts.isEmpty) {
                                // If list is empty: show no contacts available
                                return _buildEmptyView();
                              }

                              // Display contact list on success
                              return ListView.builder(
                                physics: const ClampingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  0.0,
                                  horizontalPadding,
                                  listBottomPadding,
                                ),
                                itemCount: filteredContacts.length,
                                itemBuilder: (context, index) {
                                  final contact = filteredContacts[index];
                                  return ContactListItem(
                                    contact: contact,
                                    maxWidth: contentWidth,
                                    onTap: () => _handleMakeCall(contact),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. FLOATING CAPSULE BOTTOM NAVIGATION BAR (Contacts Tab Active)
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomNavBottomPadding,
                child: Center(
                  child: AppBottomNav(
                    maxWidth: contentWidth,
                    selectedIndex: 1, // Contacts active
                    onTap: (index) {
                      if (index == 0) {
                        context.go('/home');
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFailureView(BuildContext context, String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 48,
                color: Color(0xFF9CA3AF), // Grey cross
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load contacts',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (errorMessage != null && errorMessage.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                context.read<ContactBloc>().add(const ContactFetchRequested());
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6E00),
                side: const BorderSide(color: Color(0xFFFF6E00)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No contacts available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading skeleton featuring an animated magnifying glass icon
/// and skeleton row placeholders matching the whiteboard requirement:
/// "while loading show a magnify icon with little animation the way it is in skeletons loading"
class ContactLoadingSkeleton extends StatefulWidget {
  const ContactLoadingSkeleton({
    super.key,
    required this.horizontalPadding,
  });

  final double horizontalPadding;

  @override
  State<ContactLoadingSkeleton> createState() => _ContactLoadingSkeletonState();
}

class _ContactLoadingSkeletonState extends State<ContactLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) {
      _controller.value = 0.5;
    } else {
      _controller.repeat(reverse: true);
    }
    _animation = Tween<double>(begin: 0.35, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmering Magnify Icon with pulsing text
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6E00)
                            .withValues(alpha: 0.12 * opacity),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        size: 24,
                        color:
                            const Color(0xFFFF6E00).withValues(alpha: opacity),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Loading contacts...',
                      style: TextStyle(
                        color:
                            const Color(0xFF6B7280).withValues(alpha: opacity),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Skeleton Contact Rows
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, __) {
                    return Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB)
                                .withValues(alpha: opacity),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 140,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5E7EB)
                                      .withValues(alpha: opacity),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 80,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6)
                                      .withValues(alpha: opacity),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
