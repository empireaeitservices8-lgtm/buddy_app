import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_state.dart';
import '../../viewmodels/splash_view_model.dart';
import '../registration/registration_flow_page.dart';
import '../widgets/slide_to_action.dart';
import '../widgets/sparkle_widget.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final SplashViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SplashViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onSlideToGetStarted() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegistrationFlowPage(initialMode: AuthFlowMode.login),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Stack(
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

                // Top-Left Black Sparkle
                const Positioned(
                  top: 40,
                  left: 30,
                  child: SparkleWidget(size: 28, color: AppColors.strokeBlack),
                ),

                // Top-Right Lavender Sparkle
                const Positioned(
                  top: 100,
                  right: 36,
                  child: SparkleWidget(
                    size: 22,
                    color: AppColors.accentLavender,
                  ),
                ),

                // Bottom-Left Pink Sparkle
                const Positioned(
                  bottom: 160,
                  left: 45,
                  child: SparkleWidget(size: 20, color: AppColors.accentPink),
                ),

                // Bottom-Right Black Sparkle
                const Positioned(
                  bottom: 200,
                  right: 36,
                  child: SparkleWidget(size: 32, color: AppColors.strokeBlack),
                ),

                // Main Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Center Icon Card (GabbyTalk App Logo)
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 3.0,
                          ),
                          boxShadow: AppTheme.neoShadow(
                            offset: const Offset(4, 4),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title: GabbyTalk (Styled two-tone)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: AppTypography.brandLogo.copyWith(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Gabby',
                                  style: TextStyle(color: Color(0xFF0F3064)),
                                ),
                                TextSpan(
                                  text: 'Talk',
                                  style: TextStyle(color: Color(0xFF00A79D)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Tag Pill: Real People • Meaningful Conversations
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.strokeBlack,
                            width: 2.0,
                          ),
                          boxShadow: AppTheme.neoShadow(
                            offset: const Offset(2.5, 2.5),
                          ),
                        ),
                        child: Text(
                          AppStrings.tagline,
                          style: AppTypography.badgeText.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Slide to Get Started Button
                      SlideToActionButton(
                        text: AppStrings.slideToGetStarted,
                        onCompleted: _onSlideToGetStarted,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
