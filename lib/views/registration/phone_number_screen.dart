import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/registration_view_model.dart';
import '../widgets/neo_text_field.dart';
import '../widgets/slide_to_action.dart';

class PhoneNumberView extends StatelessWidget {
  final RegistrationViewModel viewModel;

  const PhoneNumberView({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Pill Badge (LOGIN)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentLavender,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.strokeBlack,
                width: 2.0,
              ),
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
                  'LOGIN',
                  style: AppTypography.badgeText.copyWith(
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Title: What's your number?
          Text(
            AppStrings.phoneTitle,
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            AppStrings.phoneSubtitle,
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: 28),

          // Phone input field
          NeoPhoneField(
            countryCode: viewModel.countryCode,
            countryCodes: viewModel.availableCountryCodes,
            onCountryCodeChanged: viewModel.setCountryCode,
            onPhoneNumberChanged: viewModel.setPhoneNumber,
          ),

          const SizedBox(height: 32),

          // Send Verification Code Button
          SlideToActionButton(
            text: 'Send Verification Code',
            icon: Icons.phone_rounded,
            isLoading: viewModel.isLoading,
            onCompleted: () => viewModel.submitPhoneNumber(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

