import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_profile.dart';
import '../../viewmodels/registration_view_model.dart';
import '../widgets/segmented_progress_bar.dart';

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
          const SizedBox(height: 6),

          // Centered Title: Let's personalize! ✍️
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Let's personalize!",
                  style: AppTypography.headlineLarge.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textBlack,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('✍️', style: TextStyle(fontSize: 24)),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Centered Subtitle
          Center(
            child: Text(
              'Tell us about yourself to build your profile.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Progress Bar with 5 segments & vertical slider pill (5th/last step)
          const SegmentedProgressBar(
            totalSegments: 3,
            activeIndex: 2,
            label: 'PROGRESS BAR',
          ),

          const SizedBox(height: 16),

          // FIRST NAME Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.strokeBlack, width: 2.0),
              boxShadow: AppTheme.neoShadow(offset: const Offset(3.0, 3.0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 1.8,
                    ),
                  ),
                  child: const Center(
                    child: Text('👧', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'FIRST NAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textBlack,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g., Anna Daize',
                          hintStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide.none,
                          ),
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: vm.setFirstName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // AGE Label above card
          const Text(
            'AGE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 8),

          // AGE Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.strokeBlack, width: 2.0),
              boxShadow: AppTheme.neoShadow(offset: const Offset(3.0, 3.0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 1.8,
                    ),
                  ),
                  child: const Center(
                    child: Text('⏰', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g., 24',
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide.none,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide.none,
                      ),
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      vm.setAge(val);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // I IDENTIFY AS Label
          const Text(
            'I IDENTIFY AS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 10),

          // 3 Side-by-side Gender Identity Cards
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  gender: Gender.woman,
                  title: 'Woman',
                  iconText: '🪞',
                  selectedColor: const Color(0xFFFDA4AF),
                  isSelected: vm.selectedGender == Gender.woman,
                  onTap: () => vm.setGender(Gender.woman),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGenderCard(
                  gender: Gender.man,
                  title: 'Man',
                  iconText: '👔',
                  selectedColor: const Color(0xFFBAE6FD),
                  isSelected: vm.selectedGender == Gender.man,
                  onTap: () => vm.setGender(Gender.man),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGenderCard(
                  gender: Gender.nonBinary,
                  title: 'Non-Binary',
                  iconText: '⭐',
                  selectedColor: const Color(0xFFDDD6FE),
                  isSelected: vm.selectedGender == Gender.nonBinary,
                  onTap: () => vm.setGender(Gender.nonBinary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // CONTINUE CTA Button (Coral/Orange Pill)
          GestureDetector(
            onTap: vm.isLoading
                ? null
                : () {
                    vm.setFirstName(_nameController.text.trim());
                    vm.setAge(_ageController.text.trim());
                    vm.submitFirstDetails();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8B77), Color(0xFFFF6B6B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.strokeBlack, width: 2.2),
                boxShadow: AppTheme.neoShadow(offset: const Offset(3.5, 3.5)),
              ),
              child: Center(
                child: vm.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'CONTINUE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('🚀', style: TextStyle(fontSize: 18)),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGenderCard({
    required Gender gender,
    required String title,
    required String iconText,
    required Color selectedColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 104,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.strokeBlack,
            width: isSelected ? 2.4 : 1.8,
          ),
          boxShadow: AppTheme.neoShadow(
            offset: isSelected
                ? const Offset(1.5, 1.5)
                : const Offset(3.0, 3.0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.strokeBlack, width: 1.6),
              ),
              child: Center(
                child: Text(iconText, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.textBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
