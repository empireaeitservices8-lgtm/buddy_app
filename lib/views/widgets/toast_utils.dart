import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';

/// Displays a neo-brutalist styled floating toast/snackbar notification.
void showNeoToast(
  BuildContext context,
  String message, {
  bool isError = true,
  Duration duration = const Duration(seconds: 3),
}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFFECEC) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.strokeBlack,
            width: 2.0,
          ),
          boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? AppColors.errorRed : const Color(0xFF2E7D32),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBlack,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
