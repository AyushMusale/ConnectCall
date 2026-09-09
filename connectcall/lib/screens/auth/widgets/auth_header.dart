import 'package:flutter/material.dart';

import '../../../widgets/brand_logo.dart';

/// Top header section for auth screens with the ConnectCall brand logo,
/// bold headline with the highlighted orange keyword, and descriptive subtitle.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.headline = 'Connect\nwith anyone,\n',
    this.highlightWord = 'anywhere.',
    this.subtitle =
        'Make real connections\nthrough seamless calls\nand conversations.',
    this.titleFontSize = 32,
    this.subtitleFontSize = 14,
  });

  final String headline;
  final String highlightWord;
  final String subtitle;
  final double titleFontSize;
  final double subtitleFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Brand logo
        const BrandLogo(),
        const SizedBox(height: 24),
        // Headline with highlighted word
        Text.rich(
          TextSpan(
            text: headline,
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontSize: titleFontSize,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.6,
            ),
            children: [
              TextSpan(
                text: highlightWord,
                style: TextStyle(
                  color: const Color(0xFFFF6E00),
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Subtitle
        Text(
          subtitle,
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: subtitleFontSize,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
