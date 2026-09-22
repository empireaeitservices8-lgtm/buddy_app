import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/registration_view_model.dart';
import '../widgets/slide_to_action.dart';

class InterestsView extends StatelessWidget {
  final RegistrationViewModel viewModel;

  const InterestsView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scrollable content (Header + Tags + Error)
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Title
                Text(
                  'Interest ✨',
                  style: AppTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Tap tags to add your traits, likes, and hobbies to your profile.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),

                // Tags Wrap
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: viewModel.availableInterests.map((tag) {
                    final isSelected = viewModel.selectedInterests.contains(
                      tag,
                    );
                    return GestureDetector(
                      onTap: () => viewModel.toggleInterest(tag),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9.5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accentLavender
                              : AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 1.8,
                          ),
                          boxShadow: AppTheme.neoShadow(
                            offset: const Offset(2.0, 2.0),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textBlack,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Bottom CTA Pinned Bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SlideToActionButton(
            text: 'Complete Profile 🎉',
            isLoading: viewModel.isLoading,
            onCompleted: () => viewModel.completeRegistration(),
          ),
        ),
      ],
    );
  }
}
