import 'package:flutter/material.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/cartoon_theme.dart';
import '../../viewmodels/registration_view_model.dart';
import '../widgets/otp_boxes.dart';
import '../widgets/slide_to_action.dart';
import '../widgets/toast_utils.dart';

class OtpVerificationView extends StatelessWidget {
  final RegistrationViewModel viewModel;

  const OtpVerificationView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSmallScreen = screenHeight < 680;

    final displayPhone = viewModel.fullDisplayPhone.trim().isNotEmpty
        ? viewModel.fullDisplayPhone
        : '+91 98765 43210';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: isSmallScreen ? 12 : 24),

          // 1. Header Title (at TOP)
          Text(
            'Enter the code! 🔐',
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              fontSize: isSmallScreen ? 26 : 30,
              fontWeight: FontWeight.w900,
              color: CartoonColors.charcoal,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),

          // 2. Subtitle with Phone & Edit
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Code sent to $displayPhone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CartoonColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => viewModel.goBack(),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00A79D),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // 3. Center Mascot / Illustration (in the MIDDLE)
          Container(
            width: isSmallScreen ? 175 : 205,
            height: isSmallScreen ? 175 : 205,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                "assets/images/welcome.jpeg",
                fit: BoxFit.contain,
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 18 : 24),

          // 4. 4-box OTP Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: OtpInputField(
              length: 4,
              onChanged: viewModel.setOtpCode,
              onCompleted: (code) {
                viewModel.setOtpCode(code);
                viewModel.submitOtp();
              },
            ),
          ),

          const SizedBox(height: 14),

          // Resend Code CTA
          GestureDetector(
            onTap: viewModel.canResend ? viewModel.resendOtp : null,
            child: Text(
              viewModel.canResend
                  ? 'Resend code now'
                  : 'Resend code in ${viewModel.resendCountdown}s',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: viewModel.canResend
                    ? const Color(0xFF00A79D)
                    : CartoonColors.textMuted,
                decoration: viewModel.canResend
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 18 : 24),

          // 5. Slide To Verify OTP Button
          SlideToActionButton(
            text: 'SLIDE TO VERIFY OTP',
            icon: Icons.check_rounded,
            backgroundColor: CartoonColors.charcoal,
            handleColor: CartoonColors.lime,
            textColor: Colors.white,
            iconColor: CartoonColors.charcoal,
            height: 64.0,
            isLoading: viewModel.isLoading,
            onCompleted: () {
              if (viewModel.otpCode.length < 4) {
                showNeoToast(
                  context,
                  'Please enter the 4-digit code',
                  isError: true,
                );
                return;
              }
              viewModel.submitOtp();
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

