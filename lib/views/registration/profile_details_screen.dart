import 'package:buddy_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/user_profile.dart';
import '../../viewmodels/registration_view_model.dart';
import '../widgets/neo_text_field.dart';
import '../widgets/slide_to_action.dart';

class ProfileDetailsView extends StatefulWidget {
  final RegistrationViewModel viewModel;

  const ProfileDetailsView({super.key, required this.viewModel});

  @override
  State<ProfileDetailsView> createState() => _ProfileDetailsViewState();
}

class _ProfileDetailsViewState extends State<ProfileDetailsView> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.viewModel.firstName);
    _ageController = TextEditingController(
      text: widget.viewModel.age != null ? widget.viewModel.age.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Header Pill Badge (STEP 1: PROFILE)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentButter,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.strokeBlack, width: 2.0),
              boxShadow: AppTheme.neoShadow(offset: const Offset(2.5, 2.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.face_retouching_natural_rounded,
                  size: 15,
                  color: AppColors.strokeBlack,
                ),
                const SizedBox(width: 6),
                Text(
                  'YOUR AVATAR & BIO ✨',
                  style: AppTypography.badgeText.copyWith(letterSpacing: 0.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            AppStrings.firstDetails,
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.profileSubtitle,
            style: AppTypography.bodyLarge.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Male / Female Cartoon Avatar Preview
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 2.4,
                    ),
                    boxShadow: AppTheme.neoShadow(offset: const Offset(3, 3)),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      vm.selectedGender == Gender.man
                          ? 'assets/images/avatar_male_1.jpg'
                          : (vm.selectedGender == Gender.woman
                              ? 'assets/images/avatar_female_1.jpg'
                              : 'assets/images/avatar_female_2.jpg'),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Sparkle Badge on Avatar
                const Positioned(
                  top: 2,
                  right: 2,
                  child: Text('✨', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // FIRST NAME Field
          NeoTextField(
            label: AppStrings.firstNameLabel,
            hintText: AppStrings.firstNamePlaceholder,
            controller: _nameController,
            onChanged: vm.setFirstName,
          ),
          const SizedBox(height: 18),

          // AGE Field
          NeoTextField(
            label: AppStrings.ageLabel,
            hintText: AppStrings.agePlaceholder,
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: vm.setAge,
          ),
          const SizedBox(height: 18),

          // I IDENTIFY AS Section
          Text(AppStrings.identifyLabel, style: AppTypography.labelUppercase),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildGenderPill(
                gender: Gender.woman,
                label: AppStrings.genderWoman,
                activeColor: const Color(0xFFFFD1DC),
                isSelected: vm.selectedGender == Gender.woman,
                onTap: () => vm.setGender(Gender.woman),
              ),
              const SizedBox(width: 10),
              _buildGenderPill(
                gender: Gender.man,
                label: AppStrings.genderMan,
                activeColor: const Color(0xFFBAE6FD),
                isSelected: vm.selectedGender == Gender.man,
                onTap: () => vm.setGender(Gender.man),
              ),
              const SizedBox(width: 10),
              _buildGenderPill(
                gender: Gender.nonBinary,
                label: AppStrings.genderNonBinary,
                activeColor: const Color(0xFFEDE9FE),
                isSelected: vm.selectedGender == Gender.nonBinary,
                onTap: () => vm.setGender(Gender.nonBinary),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Continue Button (Swipeable)
          SlideToActionButton(
            text: AppStrings.continueText,
            isLoading: vm.isLoading,
            onCompleted: () => vm.submitFirstDetails(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGenderPill({
    required Gender gender,
    required String label,
    required Color activeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.strokeBlack,
              width: isSelected ? 2.2 : 1.8,
            ),
            boxShadow: AppTheme.neoShadow(
              offset: isSelected
                  ? const Offset(1.5, 1.5)
                  : const Offset(3.0, 3.0),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: AppColors.textBlack,
            ),
          ),
        ),
      ),
    );
  }
}
