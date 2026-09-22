import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/registration_view_model.dart';
import '../widgets/gabby_mascot_widget.dart';
import '../widgets/otp_boxes.dart';

class OtpVerificationView extends StatelessWidget {
  final RegistrationViewModel viewModel;

  const OtpVerificationView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final displayPhone = viewModel.fullDisplayPhone.trim().isNotEmpty
        ? viewModel.fullDisplayPhone
        : '+91 98765 43210';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // Mini GabbyTalk Logo
          _buildMiniLogo(),

          const SizedBox(height: 12),

          // Center Animated Mascot with Envelope & Thumbs Up
          const GabbyMascotWidget(
            pose: MascotPose.envelopeThumbsUp,
            size: 200,
          ),

          const SizedBox(height: 16),

          // Title: Enter the code!
          Text(
            'Enter the code!',
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.textBlack,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Code sent to $displayPhone.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => viewModel.goBack(),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00A79D),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4-box Pastel Gradient OTP Input
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

          const SizedBox(height: 20),

          // Resend Code in 30s / Resend now
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
                    : AppColors.textMuted,
                decoration: viewModel.canResend
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Verify and Start Talking CTA Button (Teal Pill)
          GestureDetector(
            onTap: viewModel.isLoading
                ? null
                : () {
                    viewModel.submitOtp();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2DD4BF), Color(0xFF00A79D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.strokeBlack,
                  width: 2.2,
                ),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
              ),
              child: Center(
                child: viewModel.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Verify and Start Talking!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMiniLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.strokeBlack,
              width: 1.8,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: AppTypography.brandLogo.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
            children: const [
              TextSpan(
                text: 'Gabby',
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
              TextSpan(
                text: 'Talk',
                style: TextStyle(color: Color(0xFF00A79D)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
