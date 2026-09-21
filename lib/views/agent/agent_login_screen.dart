import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_api_repository.dart';
import '../../viewmodels/agent_auth_view_model.dart';
import '../role_selection/role_selection_screen.dart';
import '../widgets/buddy_app_bar.dart';
import '../widgets/slide_to_action.dart';
import '../widgets/toast_utils.dart';
import 'agent_dashboard_screen.dart';

class AgentLoginScreen extends StatefulWidget {
  const AgentLoginScreen({super.key});

  @override
  State<AgentLoginScreen> createState() => _AgentLoginScreenState();
}

class _AgentLoginScreenState extends State<AgentLoginScreen> {
  late final AgentAuthViewModel _viewModel;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _viewModel = AgentAuthViewModel(authRepository: AuthApiRepository());
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final success = await _viewModel.login();
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AgentDashboardScreen()),
        (route) => false,
      );
    } else if (!success && mounted) {
      final error = _viewModel.errorMessage ?? 'Invalid listener credentials';
      showNeoToast(context, error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BuddyAppBar(
        title: AppStrings.appName,
        onBack: () => Navigator.of(context).maybePop(),
      ),
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
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    // Pill Badge: AGENT PORTAL
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 2.0,
                        ),
                        boxShadow: AppTheme.neoShadow(
                          offset: const Offset(2.5, 2.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.headset_mic_outlined,
                            size: 16,
                            color: AppColors.strokeBlack,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'AGENT PORTAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Heading: Agent Sign In
                    Text(
                      'Agent Sign In',
                      style: AppTypography.headlineLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Please enter your assigned Agent Username and Password to access your dashboard.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // USERNAME OR AGENT ID
                    const Text(
                      'USERNAME OR AGENT ID',
                      style: AppTypography.labelUppercase,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 2.0,
                        ),
                        boxShadow: AppTheme.neoShadow(
                          offset: const Offset(2.5, 2.5),
                        ),
                      ),
                      child: TextField(
                        controller: _usernameController,
                        onChanged: _viewModel.setUsername,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textBlack,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. LISTENER_101',
                          hintStyle: TextStyle(
                            color: AppColors.textPlaceholder,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.strokeBlack,
                            size: 22,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // PASSWORD
                    const Text('PASSWORD', style: AppTypography.labelUppercase),
                    const SizedBox(height: 8),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.strokeBlack,
                          width: 2.0,
                        ),
                        boxShadow: AppTheme.neoShadow(
                          offset: const Offset(2.5, 2.5),
                        ),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _viewModel.obscurePassword,
                        onChanged: _viewModel.setPassword,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textBlack,
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••••••',
                          hintStyle: const TextStyle(
                            color: AppColors.textPlaceholder,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.strokeBlack,
                            size: 22,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _viewModel.obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.strokeBlack,
                              size: 20,
                            ),
                            onPressed: _viewModel.togglePasswordVisibility,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Checkbox & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _rememberMe
                                      ? AppColors.strokeBlack
                                      : AppColors.cardWhite,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.strokeBlack,
                                    width: 1.8,
                                  ),
                                ),
                                child: _rememberMe
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textBlack,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quick Test Agent Helper Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1FAC0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.strokeBlack, width: 1.5),
                        boxShadow: AppTheme.neoShadow(offset: const Offset(1.5, 1.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.science_outlined,
                            size: 18,
                            color: AppColors.strokeBlack,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Test Account: prof_anjali_nair',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textBlack,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _usernameController.text = 'prof_anjali_nair';
                              _viewModel.setUsername('prof_anjali_nair');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.strokeBlack,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Autofill',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Slide to Log In
                    SlideToActionButton(
                      text: 'Slide to Log In',
                      icon: Icons.phone_rounded,
                      handleColor: const Color(
                        0xFFFFF7CE,
                      ), // Pale yellow handle
                      isLoading: _viewModel.isLoading,
                      onCompleted: _onLogin,
                    ),
                    const SizedBox(height: 18),

                    // Not an Agent? Switch Role Button
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.strokeBlack,
                              width: 1.8,
                            ),
                            boxShadow: AppTheme.neoShadow(
                              offset: const Offset(2.5, 2.5),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                size: 18,
                                color: AppColors.strokeBlack,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Not an Agent? Switch Role',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: AppColors.textBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  ),
);
  }
}
