import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_state.dart';
import '../../data/models/user_role.dart';
import '../../data/services/mock_auth_service.dart';
import '../../viewmodels/role_view_model.dart';
import '../agent/agent_login_screen.dart';
import '../registration/registration_flow_page.dart';
import '../widgets/buddy_app_bar.dart';
import '../widgets/slide_to_action.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late final RoleSelectionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Using default mock repository instance
    _viewModel = RoleSelectionViewModel(authRepository: MockAuthService());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_viewModel.isUserSelected) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              const RegistrationFlowPage(initialMode: AuthFlowMode.login),
        ),
      );
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const AgentLoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BuddyAppBar(title: AppStrings.appName),
      body: Stack(
        children: [
          // 1. Top-Right Soft Sage Circle
          Positioned(
            top: -65,
            right: -60,
            child: Container(
              width: 270,
              height: 270,
              decoration: const BoxDecoration(
                color: Color(0xFFC3E2A0),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Middle-Left Warm Peach Circle
          Positioned(
            top: 270,
            left: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                color: Color(0xFFE8D4AF),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 3. Bottom-Right Subtle Soft Lime Glow Circle
          Positioned(
            top: 500,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                color: Color(0xFFCEF17D),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return Column(
                  children: [
                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SELECT YOUR ROLE Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentLavender,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.strokeBlack,
                                  width: 2.0,
                                ),
                                boxShadow: AppTheme.neoShadow(
                                  offset: const Offset(2.5, 2.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 16,
                                    color: AppColors.strokeBlack,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppStrings.selectYourRole,
                                    style: AppTypography.badgeText.copyWith(
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Heading
                            Text(
                              AppStrings.roleQuestion,
                              style: AppTypography.headlineLarge.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Subtitle
                            Text(
                              AppStrings.roleSubtitle,
                              style: AppTypography.bodyLarge,
                            ),
                            const SizedBox(height: 24),

                            // Option 1: User Card
                            _buildRoleCard(
                              role: UserRole.user,
                              isSelected: _viewModel.isUserSelected,
                              icon: Icons.person_rounded,
                              title: AppStrings.roleUserTitle,
                              badgeText: AppStrings.roleUserBadge,
                              description: AppStrings.roleUserDesc,
                              onTap: () => _viewModel.selectRole(UserRole.user),
                            ),
                            const SizedBox(height: 16),

                            // Option 2: Agent Card
                            _buildRoleCard(
                              role: UserRole.agent,
                              isSelected: _viewModel.isAgentSelected,
                              icon: Icons.support_agent_rounded,
                              title: AppStrings.roleAgentTitle,
                              badgeText: AppStrings.roleAgentBadge,
                              description: AppStrings.roleAgentDesc,
                              onTap: () =>
                                  _viewModel.selectRole(UserRole.agent),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // Fixed Bottom Action Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SlideToActionButton(
                            text: _viewModel.actionButtonText,
                            onCompleted: _onContinue,
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: _viewModel.isUserSelected
                                ? GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegistrationFlowPage(
                                                initialMode: AuthFlowMode.signUp,
                                              ),
                                        ),
                                      );
                                    },
                                    child: RichText(
                                      text: const TextSpan(
                                        style: AppTypography.bodyMedium,
                                        children: [
                                          TextSpan(text: AppStrings.newToBuddy),
                                          TextSpan(
                                            text: AppStrings.signUpNow,
                                            style: AppTypography.linkText,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardWhite.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.strokeBlack,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock_outline_rounded,
                                          size: 14,
                                          color: AppColors.strokeBlack,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Agent accounts are provisioned by Admin',
                                          style: AppTypography.bodySmall.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required bool isSelected,
    required IconData icon,
    required String title,
    required String badgeText,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentLavender : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.strokeBlack,
            width: AppTheme.strokeWidth + 0.5,
          ),
          boxShadow: AppTheme.neoShadow(offset: const Offset(4, 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box (white rounded square)
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 2.0,
                    ),
                  ),
                  child: Icon(icon, size: 32, color: AppColors.strokeBlack),
                ),
                const SizedBox(width: 14),

                // Title and Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.cardWhite
                              : AppColors.accentLavenderLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: AppTypography.badgeText.copyWith(
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Radio / Checkmark Icon
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.strokeBlack
                        : AppColors.cardWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.strokeBlack,
                      width: 2.0,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: AppColors.cardWhite,
                          size: 18,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
