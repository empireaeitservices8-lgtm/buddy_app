import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_state.dart';
import '../../data/models/user_role.dart';
import '../../data/services/mock_auth_service.dart';
import '../../viewmodels/role_view_model.dart';
import '../agent/agent_login_screen.dart';
import '../registration/registration_flow_page.dart';
import '../widgets/neo_background.dart';
import '../widgets/slide_to_action.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late final RoleSelectionViewModel _viewModel;
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Just Talk',
      'emoji': '❤️',
      'pillColor': const Color(0xFFFF8DA1),
      'asset': 'assets/images/categories/just_talk.jpg',
      'role': UserRole.user,
    },
    {
      'title': 'Advice',
      'emoji': '💡',
      'pillColor': const Color(0xFF8392F8),
      'asset': 'assets/images/categories/advice.jpg',
      'role': UserRole.agent,
    },
    {
      'title': 'Friendship',
      'emoji': '🎯',
      'pillColor': const Color(0xFFF0C850),
      'asset': 'assets/images/categories/friendly_conversation.jpg',
      'role': UserRole.user,
    },
    {
      'title': 'Career',
      'emoji': '💼',
      'pillColor': const Color(0xFF00A79D),
      'asset': 'assets/images/categories/career.png',
      'role': UserRole.agent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = RoleSelectionViewModel(authRepository: MockAuthService());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onContinue() {
    final selectedRole =
        _categories[_selectedCategoryIndex]['role'] as UserRole;
    _viewModel.selectRole(selectedRole);

    if (selectedRole == UserRole.user) {
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
      backgroundColor: const Color(0xFFFBF8EE),
      body: NeoBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Column(
                children: [
                  // Top Header with Coin Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.strokeBlack,
                          ),
                        ),
                        // Coin Balance Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7CE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.8,
                            ),
                            boxShadow: AppTheme.neoShadow(
                              offset: const Offset(1.5, 1.5),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🪙', style: TextStyle(fontSize: 12)),
                              SizedBox(width: 4),
                              Text(
                                '300',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Heading: Who do you want to be?
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Who do you want to be?',
                        style: AppTypography.headlineLarge.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBlack,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2x2 Grid of Category Cards
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.88,
                            ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final item = _categories[index];
                          final isSelected = _selectedCategoryIndex == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: AppColors.strokeBlack,
                                  width: isSelected ? 2.6 : 1.8,
                                ),
                                boxShadow: AppTheme.neoShadow(
                                  offset: isSelected
                                      ? const Offset(1.5, 1.5)
                                      : const Offset(3.5, 3.5),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Background Illustration Image
                                  Positioned.fill(
                                    bottom: 38,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Image.asset(
                                        item['asset'] as String,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            item['emoji'] as String,
                                            style: const TextStyle(
                                              fontSize: 48,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Bottom Pill Tag
                                  Positioned(
                                    left: 10,
                                    right: 10,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item['pillColor'] as Color,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppColors.strokeBlack,
                                          width: 1.4,
                                        ),
                                        boxShadow: AppTheme.neoShadow(
                                          offset: const Offset(1.5, 1.5),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item['emoji'] as String,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item['title'] as String,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Subtext
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Share your interests & background',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  // Slide / Action Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: SlideToActionButton(
                      text: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      backgroundColor: const Color(0xFF1B2430),
                      handleColor: const Color(0xFFE0E7FF),
                      textColor: Colors.white,
                      iconColor: AppColors.strokeBlack,
                      onCompleted: _onContinue,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
