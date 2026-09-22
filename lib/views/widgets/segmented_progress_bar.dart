import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class SegmentedProgressBar extends StatelessWidget {
  final int totalSegments;
  final int activeIndex; // 0-indexed
  final String? label;

  const SegmentedProgressBar({
    super.key,
    this.totalSegments = 5,
    required this.activeIndex,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = label ?? 'PROGRESS BAR';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final segmentWidth = totalWidth / totalSegments;
            final handleWidth = 10.0;
            final handleHeight = 24.0;
            final handleOffset = (activeIndex * segmentWidth) +
                (segmentWidth / 2) -
                (handleWidth / 2);

            return SizedBox(
              height: 28,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Base track segments
                  Row(
                    children: List.generate(totalSegments, (index) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: index < totalSegments - 1 ? 6.0 : 0.0,
                          ),
                          height: 7.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      );
                    }),
                  ),

                  // Vertical Pill Handle (matches Image 1)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    left: handleOffset.clamp(0.0, totalWidth - handleWidth),
                    child: Container(
                      width: handleWidth,
                      height: handleHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6D8A8),
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 1.8,
                        ),
                        boxShadow: AppTheme.neoShadow(
                          offset: const Offset(1.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (displayLabel.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            displayLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppColors.textBlack,
            ),
          ),
        ],
      ],
    );
  }
}
