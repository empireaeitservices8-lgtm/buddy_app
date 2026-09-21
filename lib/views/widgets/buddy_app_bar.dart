import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'sparkle_widget.dart';

class BuddyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showSparkle;
  final bool showBack;

  const BuddyAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.showSparkle = true,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showBack)
              InkWell(
                onTap: onBack ?? () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 22,
                    color: AppColors.strokeBlack,
                  ),
                ),
              )
            else
              const SizedBox(width: 34),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            if (showSparkle)
              const SparkleWidget(
                size: 20,
                color: AppColors.strokeBlack,
              )
            else
              const SizedBox(width: 34),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
