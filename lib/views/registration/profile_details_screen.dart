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
          const SizedBox(height: 12),

          // Title
          Text(
            AppStrings.firstDetails,
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),

          // Subtitle
          Text(AppStrings.profileSubtitle, style: AppTypography.bodyLarge),
          const SizedBox(height: 24),

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
                isSelected: vm.selectedGender == Gender.woman,
                onTap: () => vm.setGender(Gender.woman),
              ),
              const SizedBox(width: 10),
              _buildGenderPill(
                gender: Gender.man,
                label: AppStrings.genderMan,
                isSelected: vm.selectedGender == Gender.man,
                onTap: () => vm.setGender(Gender.man),
              ),
              const SizedBox(width: 10),
              _buildGenderPill(
                gender: Gender.nonBinary,
                label: AppStrings.genderNonBinary,
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
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentLavender : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.strokeBlack, width: 2.0),
          ),
          child: Text(
            label,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textBlack,
            ),
          ),
        ),
      ),
    );
  }
}
