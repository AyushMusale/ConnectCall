import 'package:flutter/material.dart';

/// Horizontal list of call filter chips: "All", "Missed", "Incoming", "Outgoing".
class CallFilterChips extends StatelessWidget {
  const CallFilterChips({
    super.key,
    required this.maxWidth,
    this.selectedFilter = 'All',
    this.onFilterChanged,
  });

  final double maxWidth;
  final String selectedFilter;
  final ValueChanged<String>? onFilterChanged;

  static const List<String> filters = [
    'All',
    'Missed',
    'Incoming',
    'Outgoing',
  ];

  @override
  Widget build(BuildContext context) {
    final chipHeight = (maxWidth * 0.09).clamp(34.0, 42.0);
    final horizontalPadding = (maxWidth * 0.036).clamp(12.0, 20.0);
    final fontSize = (maxWidth * 0.035).clamp(12.5, 14.5);

    return SizedBox(
      height: chipHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: filters.asMap().entries.map((entry) {
            final index = entry.key;
            final filter = entry.value;
            final isSelected = filter == selectedFilter;

            return Padding(
              padding: EdgeInsets.only(
                right: index == filters.length - 1 ? 0 : 10.0,
              ),
              child: InkWell(
                onTap: () => onFilterChanged?.call(filter),
                borderRadius: BorderRadius.circular(chipHeight / 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF6E00)
                        : const Color(0xFFF7EFE8),
                    borderRadius: BorderRadius.circular(chipHeight / 2),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF2B2F3A),
                      fontSize: fontSize,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
