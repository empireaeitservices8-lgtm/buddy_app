import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class SegmentedProgressBar extends StatelessWidget {
  final int totalSegments;
  final int activeIndex; // 0-indexed

  const SegmentedProgressBar({
    super.key,
    this.totalSegments = 3,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        children: List.generate(totalSegments, (index) {
          final isFilled = index <= activeIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                right: index < totalSegments - 1 ? 8.0 : 0.0,
              ),
              height: 8.5,
              decoration: BoxDecoration(
                color: isFilled ? const Color(0xFF0F2444) : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: AppColors.strokeBlack,
                  width: 1.8,
                ),
                boxShadow: AppTheme.neoShadow(offset: const Offset(1.5, 1.5)),
              ),
            ),
          );
        }),
      ),
    );
  }
}
