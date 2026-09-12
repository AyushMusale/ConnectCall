import 'package:flutter/material.dart';

/// Styled action card button (Audio Call / Video Call) matching makeCall_page.png design.
class CallActionCard extends StatelessWidget {
  const CallActionCard({
    super.key,
    required this.height,
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.onTap,
  });

  final double height;
  final IconData icon;
  final double iconSize;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF0E5),
      borderRadius: BorderRadius.circular(18.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.0),
        splashColor: const Color(0xFFFF6E00).withValues(alpha: 0.15),
        highlightColor: const Color(0xFFFF6E00).withValues(alpha: 0.08),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: const Color(0xFFFFE2CC),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFFFF6E00),
                size: iconSize,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFFF6E00),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
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
