import 'package:flutter/material.dart';
import '../../core/theme/cartoon_theme.dart';

/// Reusable Cartoon App Bar
class BuddyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showSparkle;
  final bool showBack;
  final Widget? trailing;

  const BuddyAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.showSparkle = true,
    this.showBack = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showBack)
              GestureDetector(
                onTap: onBack ?? () => Navigator.maybePop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CartoonColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CartoonColors.ink,
                      width: CartoonDimensions.borderWidthThin,
                    ),
                    boxShadow: CartoonDimensions.shadowSmall(
                      offset: const Offset(2, 2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: CartoonColors.ink,
                  ),
                ),
              )
            else
              const SizedBox(width: 40),
            Text(
              title,
              style: const TextStyle(
                fontFamily: CartoonTextTheme.fontFamily,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: CartoonColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            if (trailing != null)
              trailing!
            else if (showSparkle)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CartoonColors.yellowSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CartoonColors.ink,
                    width: CartoonDimensions.borderWidthThin,
                  ),
                  boxShadow: CartoonDimensions.shadowSmall(
                    offset: const Offset(2, 2),
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('✨', style: TextStyle(fontSize: 16)),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

