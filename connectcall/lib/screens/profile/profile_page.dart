import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../injection.dart';
import '../../models/profile_model.dart';
import '../../services/firebase/profile.service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_header.dart';
import '../auth/bloc/auth_bloc.dart';

/// Profile screen matching profile.png, allowing users to view and update
/// their display name, avatar, and sign out of their account.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.profileServiceOverride,
    this.onSignOut,
  });

  final ProfileService? profileServiceOverride;
  final VoidCallback? onSignOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  ProfileService get _service =>
      widget.profileServiceOverride ?? profileService;

  ProfileModel? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSigningOut = false;
  StreamSubscription<ProfileModel?>? _profileSub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final initial = await _service.getProfile();
      if (mounted) {
        setState(() {
          _profile = initial;
          if (initial != null && _nameController.text.isEmpty) {
            _nameController.text = initial.name;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Real-time updates subscription
    try {
      _profileSub?.cancel();
      _profileSub = _service.watchProfile().listen((updated) {
        if (mounted && updated != null) {
          setState(() {
            _profile = updated;
            if (_nameController.text.isEmpty) {
              _nameController.text = updated.name;
            }
          });
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSaveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty.'),
          backgroundColor: Color(0xFFEA3829),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await _service.updateName(newName);
      if (mounted) {
        setState(() {
          _profile = updated;
          _isSaving = false;
        });
        _nameFocusNode.unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Profile updated successfully!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: const Color(0xFFEA3829),
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;
    setState(() {
      _isSigningOut = true;
    });

    try {
      await _service.signOut();
    } catch (_) {}

    if (mounted) {
      if (widget.onSignOut != null) {
        widget.onSignOut!();
        return;
      }
      try {
        context.read<AuthBloc>().add(const AuthResetState());
      } catch (_) {}
      try {
        context.go('/login');
      } catch (_) {}
    }
  }

  Future<void> _showEditAvatarDialog() async {
    final avatarController = TextEditingController(
      text: _profile?.avatar ?? '',
    );

    final newUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Update Avatar URL',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter an image URL for your profile photo:',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: avatarController,
              decoration: InputDecoration(
                hintText: 'https://...',
                filled: true,
                fillColor: const Color(0xFFFBF4EE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6E00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(avatarController.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newUrl != null && newUrl.isNotEmpty && mounted) {
      try {
        final updated = await _service.updateAvatar(newUrl);
        if (mounted) {
          setState(() {
            _profile = updated;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar updated successfully!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    const defaultAvatarUrl =
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400';

    final displayName = _profile?.name.isNotEmpty == true
        ? _profile!.name
        : (_nameController.text.isNotEmpty
            ? _nameController.text
            : 'Ayush Sharma');

    final displayEmail = _profile?.email.isNotEmpty == true
        ? _profile!.email
        : 'ayush.sharma@example.com';

    final avatarUrl = _profile?.avatar?.isNotEmpty == true
        ? _profile!.avatar!
        : defaultAvatarUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                (constraints.maxWidth * 0.055).clamp(16.0, 24.0);
            final contentWidth = constraints.maxWidth;
            final bottomNavBottomPadding =
                (constraints.maxHeight * 0.02).clamp(12.0, 20.0);
            final avatarRadius =
                (constraints.maxWidth * 0.17).clamp(60.0, 75.0);

            return Stack(
              children: [
                // 1. SCROLLABLE CONTENT BODY
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      top: 14,
                      bottom: 120, // space above bottom nav
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // App Brand Header with search and overflow menu
                        AppHeader(
                          maxWidth: contentWidth,
                          onSignOut: _handleSignOut,
                        ),
                        const SizedBox(height: 36),

                        // Centered Avatar with Camera edit badge overlay
                        Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Circular Avatar
                              Container(
                                width: avatarRadius * 2,
                                height: avatarRadius * 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFFE8D6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1E242E)
                                          .withValues(alpha: 0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: const Color(0xFFFFE6D4),
                                        alignment: Alignment.center,
                                        child: Text(
                                          displayName.isNotEmpty
                                              ? displayName[0].toUpperCase()
                                              : 'A',
                                          style: TextStyle(
                                            color: const Color(0xFFFF6E00),
                                            fontSize: avatarRadius * 0.8,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loading) {
                                      if (loading == null) return child;
                                      return Container(
                                        color: const Color(0xFFFFE6D4),
                                        alignment: Alignment.center,
                                        child: const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFFF6E00),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // Camera Edit Badge
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: _showEditAvatarDialog,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE6D4),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFCF8F5),
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1E242E)
                                              .withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.camera_alt_outlined,
                                        size: 20,
                                        color: Color(0xFFFF6E00),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Email subtitle
                        Text(
                          displayEmail,
                          style: const TextStyle(
                            color: Color(0xFF757B88),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Name Input Section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Name',
                            style: TextStyle(
                              color: const Color(0xFF1E242E).withValues(alpha: 0.75),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Input Container Field
                        Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBF4EE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFE8D6),
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            key: const Key('profile_name_input'),
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            style: const TextStyle(
                              color: Color(0xFF1E242E),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'Enter your name',
                              hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Primary "Save" Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            key: const Key('profile_save_button'),
                            onPressed: _isSaving ? null : _handleSaveName,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6E00),
                              disabledBackgroundColor:
                                  const Color(0xFFFF6E00).withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Secondary "Log Out" Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            key: const Key('profile_logout_button'),
                            onPressed: _isSigningOut ? null : _handleSignOut,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFECEB),
                              foregroundColor: const Color(0xFFEA3829),
                              side: const BorderSide(
                                color: Color(0xFFFFD4D1),
                                width: 1.2,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSigningOut
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Color(0xFFEA3829),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.logout_rounded,
                                        size: 20,
                                        color: Color(0xFFEA3829),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Log Out',
                                        style: TextStyle(
                                          color: Color(0xFFEA3829),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. FLOATING CAPSULE BOTTOM NAVIGATION BAR
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: bottomNavBottomPadding,
                  child: Center(
                    child: AppBottomNav(
                      maxWidth: contentWidth,
                      selectedIndex: 2, // Profile selected
                      onTap: (index) {
                        if (index == 0) {
                          context.go('/home');
                        } else if (index == 1) {
                          context.go('/contacts');
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
