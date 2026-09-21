import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/registration_view_model.dart';
import '../widgets/otp_boxes.dart';
import '../widgets/slide_to_action.dart';

class OtpVerificationView extends StatelessWidget {
  final RegistrationViewModel viewModel;

  const OtpVerificationView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Pill Badge (VERIFY OTP)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentLavender,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.strokeBlack, width: 2.0),
              boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: AppColors.strokeBlack,
                ),
                const SizedBox(width: 6),
                Text(
                  'VERIFY OTP',
                  style: AppTypography.badgeText.copyWith(letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Title: Enter OTP Code
          Text(
            'Enter OTP Code',
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle with formatted phone
          Text(
            'We sent a 4-digit verification code to ${viewModel.fullDisplayPhone.isNotEmpty ? viewModel.fullDisplayPhone : "+1 02588"}',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),

          // 4-box OTP input
          OtpInputField(
            length: 4,
            onChanged: viewModel.setOtpCode,
            onCompleted: (code) {
              viewModel.setOtpCode(code);
              viewModel.submitOtp();
            },
          ),

          const SizedBox(height: 24),

          // Resend Code button / timer
          Center(
            child: GestureDetector(
              onTap: viewModel.canResend ? viewModel.resendOtp : null,
              child: Text(
                viewModel.canResend
                    ? AppStrings.resendCode
                    : '⏱️ Resend code in ${viewModel.resendCountdown}s',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: viewModel.canResend
                      ? AppColors.textBlack
                      : AppColors.textMuted,
                  decoration: viewModel.canResend
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Verify & Login Button (Swipeable)
          SlideToActionButton(
            text: 'Verify',
            icon: Icons.phone_rounded,
            isLoading: viewModel.isLoading,
            onCompleted: () => viewModel.submitOtp(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
