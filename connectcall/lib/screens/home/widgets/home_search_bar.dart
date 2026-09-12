import 'package:flutter/material.dart';

/// Styled search field matching the ConnectCall home page search bar.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.maxWidth,
    this.onChanged,
    this.controller,
    this.readOnly = false,
    this.enabled = true,
  });

  final double maxWidth;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool readOnly;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final barHeight = (maxWidth * 0.12).clamp(44.0, 52.0);
    final iconSize = (maxWidth * 0.05).clamp(19.0, 22.0);
    final fontSize = (maxWidth * 0.038).clamp(13.5, 15.5);

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF7EFE8),
        borderRadius: BorderRadius.circular(barHeight / 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: iconSize,
            color: const Color(0xFF757B88),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              readOnly: readOnly,
              enabled: enabled,
              style: TextStyle(
                fontSize: fontSize,
                color: const Color(0xFF1E242E),
              ),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(
                  fontSize: fontSize,
                  color: const Color(0xFF8A909E),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
