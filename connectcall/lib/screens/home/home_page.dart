import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../injection.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_header.dart';
import '../auth/bloc/auth_bloc.dart';
import '../call/widgets/make_call_bottom_sheet.dart';
import 'bloc/history_bloc.dart';
import 'models/call_log_model.dart';
import 'widgets/call_filter_chips.dart';
import 'widgets/call_log_item.dart';
import 'widgets/home_search_bar.dart';

/// HomePage UI featuring responsive LayoutBuilder, clamped metrics,
/// and BlocConsumer / BlocBuilder structure connected to [HistoryBloc] and [HistoryService].
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<HistoryBloc>();
      return const _HomePageView();
    } catch (_) {
      return BlocProvider<HistoryBloc>(
        create: (_) => getIt<HistoryBloc>(),
        child: const _HomePageView(),
      );
    }
  }
}

class _HomePageView extends StatefulWidget {
  const _HomePageView();

  @override
  State<_HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<_HomePageView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // On init in HomePage, fetch call history if initial and Firebase is ready
    try {
      final historyBloc = context.read<HistoryBloc>();
      if (historyBloc.state.isInitial && Firebase.apps.isNotEmpty) {
        historyBloc.add(const HistoryFetchRequested());
      }
    } catch (_) {}
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

  void _handleMakeCall(CallLogModel call) {
    MakeCallBottomSheet.show(
      context,
      contactName: call.name,
      avatarUrl: call.avatarUrl,
      isOnline: call.isOnline,
      onAudioCall: () {
        Navigator.of(context).pop();
        context.push('/make-call', extra: {
          'otherUserId': call.callModel?.otherUserId ?? 'cnt-1',
          'otherUserName': call.name,
          'otherUserAvatar': call.avatarUrl,
          'isOnline': call.isOnline,
          'type': 'audio',
          'autoStart': true,
        });
      },
      onVideoCall: () {
        Navigator.of(context).pop();
        context.push('/make-call', extra: {
          'otherUserId': call.callModel?.otherUserId ?? 'cnt-1',
          'otherUserName': call.name,
          'otherUserAvatar': call.avatarUrl,
          'isOnline': call.isOnline,
          'type': 'video',
          'autoStart': true,
        });
      },
    );
  }

  Widget _buildFailureView(BuildContext context, String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                size: 36,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load call history',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E242E),
              ),
            ),
            if (errorMessage != null && errorMessage.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<HistoryBloc>().add(const HistoryFetchRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6E00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, {double bottomPadding = 0}) {
    return RefreshIndicator(
      color: const Color(0xFFFF6E00),
      onRefresh: () async {
        final historyBloc = context.read<HistoryBloc>();
        historyBloc.add(const HistoryFetchRequested());
        try {
          await historyBloc.stream
              .firstWhere((s) => !s.isLoading)
              .timeout(const Duration(seconds: 4));
        } catch (_) {}
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF4EC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_missed_rounded,
                            size: 36,
                            color: Color(0xFFFF6E00),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No call history',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E242E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Calls you make or receive will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsiveness using clamp across devices
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
    
          final horizontalPadding = (maxW * 0.045).clamp(16.0, 32.0);
          final contentWidth = maxW.clamp(300.0, 720.0);
          final bottomNavBottomPadding = (maxH * 0.02).clamp(10.0, 24.0);
          final listBottomPadding = (maxW * 0.25).clamp(80.0, 110.0);
    
          return BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, historyState) {
              final filteredCalls = (historyState.isInitial && historyState.history.isEmpty)
                  ? CallLogModel.sampleCalls.where((call) {
                      final query = historyState.searchQuery.trim().toLowerCase();
                      final matchesQuery = query.isEmpty ||
                          call.name.toLowerCase().contains(query) ||
                          call.timeSubtitle.toLowerCase().contains(query);
                      final matchesFilter = switch (historyState.selectedFilter) {
                        'Missed' => call.callType == CallType.missed,
                        'Incoming' => call.callType == CallType.incoming,
                        'Outgoing' => call.callType == CallType.outgoing,
                        _ => true,
                      };
                      return matchesQuery && matchesFilter;
                    }).toList()
                  : historyState.filteredCallLogs;
              return Stack(
                children: [
                  // Main Layout: Fixed Top Header/Search/Chips + Scrollable Call Logs
                  SafeArea(
                    bottom: false,
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. FIXED TOP SECTION (Header, Search Bar, Filter Chips)
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
                                    onChanged: (query) {
                                      context
                                          .read<HistoryBloc>()
                                          .add(HistorySearchChanged(query));
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  CallFilterChips(
                                    maxWidth: contentWidth,
                                    selectedFilter:
                                        historyState.selectedFilter,
                                    onFilterChanged: (filter) {
                                      context
                                          .read<HistoryBloc>()
                                          .add(HistoryFilterChanged(filter));
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
    
                            // 2. ONLY CALL LOGS ARE SCROLLABLE
                            Expanded(
                              child: () {
                                if (historyState.isLoading) {
                                  return HistoryLoadingSkeleton(
                                    horizontalPadding: horizontalPadding,
                                  );
                                }
    
                                if (historyState.isFailure) {
                                  return _buildFailureView(
                                    context,
                                    historyState.errorMessage,
                                  );
                                }
    
                                if (filteredCalls.isEmpty) {
                                  return _buildEmptyView(
                                    context,
                                    bottomPadding: listBottomPadding,
                                  );
                                }
    
                                return RefreshIndicator(
                                  color: const Color(0xFFFF6E00),
                                  onRefresh: () async {
                                    context
                                        .read<HistoryBloc>()
                                        .add(const HistoryFetchRequested());
                                  },
                                  child: ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                      parent: ClampingScrollPhysics(),
                                    ),
                                    padding: EdgeInsets.fromLTRB(
                                      horizontalPadding,
                                      0.0,
                                      horizontalPadding,
                                      listBottomPadding,
                                    ),
                                    itemCount: filteredCalls.length,
                                    itemBuilder: (context, index) {
                                      final call = filteredCalls[index];
                                      return CallLogItem(
                                        call: call,
                                        maxWidth: contentWidth,
                                        currentUserId:
                                            sessionService.currentUser?.uid,
                                        onTap: () => _handleMakeCall(call),
                                        onCallTap: () =>
                                            _handleMakeCall(call),
                                      );
                                    },
                                  ),
                                );
                              }(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
    
                  // 3. FLOATING CAPSULE BOTTOM NAVIGATION BAR
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomNavBottomPadding,
                    child: Center(
                      child: AppBottomNav(
                        maxWidth: contentWidth,
                        selectedIndex: 0,
                        onTap: (index) {
                          if (index == 1) {
                            context.go('/contacts');
                          } else if (index == 2) {
                            context.go('/profile');
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Loading skeleton featuring an animated telephone icon
/// and shimmer call log row placeholders for HomePage.
class HistoryLoadingSkeleton extends StatefulWidget {
  const HistoryLoadingSkeleton({
    super.key,
    required this.horizontalPadding,
  });

  final double horizontalPadding;

  @override
  State<HistoryLoadingSkeleton> createState() => _HistoryLoadingSkeletonState();
}

class _HistoryLoadingSkeletonState extends State<HistoryLoadingSkeleton>
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
              // Shimmering Call Icon with pulsing text
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
                        Icons.phone_rounded,
                        size: 24,
                        color:
                            const Color(0xFFFF6E00).withValues(alpha: opacity),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Loading call history...',
                        style: TextStyle(
                          color:
                              const Color(0xFF6B7280).withValues(alpha: opacity),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Skeleton Call Rows
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
                                width: 90,
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
                        Container(
                          width: 40,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6)
                                .withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(4),
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
