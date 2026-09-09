import 'package:flutter/material.dart';

/// Reusable ConnectCall brand logo with the signature speech bubble icon
/// and two-tone styled typography ("Connect" + "Call").
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.fontSize = 22,
    this.iconSize = 34,
  });

  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand icon: Speech bubble containing telephone handset
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6E00),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(iconSize * 0.42),
              topRight: Radius.circular(iconSize * 0.42),
              bottomRight: Radius.circular(iconSize * 0.42),
              bottomLeft: Radius.circular(iconSize * 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6E00).withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.phone_rounded,
              size: iconSize * 0.52,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Brand text: Connect (dark) + Call (orange)
        Text.rich(
          TextSpan(
            text: 'Connect',
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            children: [
              TextSpan(
                text: 'Call',
                style: TextStyle(
                  color: const Color(0xFFFF6E00),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
