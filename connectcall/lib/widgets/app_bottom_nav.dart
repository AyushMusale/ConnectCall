import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Floating capsule bottom navigation dock used consistently across all ConnectCall pages.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.maxWidth,
    this.selectedIndex = 0,
    this.onTap,
  });

  final double maxWidth;
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    if (index == selectedIndex) return;

    if (index == 0) {
      context.go('/home');
    } else if (index == 1) {
      context.go('/contacts');
    } else if (index == 2) {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final navWidth = (maxWidth * 0.88).clamp(270.0, 400.0);
    final navHeight = (maxWidth * 0.18).clamp(66.0, 76.0);
    final iconPillWidth = (navWidth * 0.22).clamp(52.0, 68.0);
    final iconPillHeight = (navHeight * 0.44).clamp(28.0, 34.0);
    final iconSize = (maxWidth * 0.052).clamp(19.0, 23.0);
    final labelSize = (maxWidth * 0.028).clamp(10.5, 12.0);

    return Container(
      width: navWidth,
      height: navHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF4EE),
        borderRadius: BorderRadius.circular(navHeight / 2),
        border: Border.all(
          color: const Color(0xFFFFE8D6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E242E).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          // 1. Calls Tab
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 0,
              label: 'Calls',
              icon: Icons.phone_rounded,
              isSelected: selectedIndex == 0,
              iconPillWidth: iconPillWidth,
              iconPillHeight: iconPillHeight,
              iconSize: iconSize,
              labelSize: labelSize,
            ),
          ),

          // 2. Contacts Tab
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 1,
              label: 'Contacts',
              icon: Icons.people_alt_rounded,
              isSelected: selectedIndex == 1,
              iconPillWidth: iconPillWidth,
              iconPillHeight: iconPillHeight,
              iconSize: iconSize,
              labelSize: labelSize,
            ),
          ),

          // 3. Profile Tab
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 2,
              label: 'Profile',
              icon: Icons.person_rounded,
              isSelected: selectedIndex == 2,
              iconPillWidth: iconPillWidth,
              iconPillHeight: iconPillHeight,
              iconSize: iconSize,
              labelSize: labelSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
    required double iconPillWidth,
    required double iconPillHeight,
    required double iconSize,
    required double labelSize,
  }) {
    const activeColor = Color(0xFFFF6E00);
    const inactiveColor = Color(0xFF6B7280);
    final itemColor = isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: () => _handleTap(context, index),
      borderRadius: BorderRadius.circular(24),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill capsule behind the icon for selected state
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: iconPillWidth,
                height: iconPillHeight,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFE6D4) : Colors.transparent,
                  borderRadius: BorderRadius.circular(iconPillHeight / 2),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: itemColor,
                ),
              ),
              const SizedBox(height: 2),
              // Text label below the icon pill
              Text(
                label,
                style: TextStyle(
                  color: itemColor,
                  fontSize: labelSize,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Type alias for backward compatibility.
typedef HomeBottomNav = AppBottomNav;
