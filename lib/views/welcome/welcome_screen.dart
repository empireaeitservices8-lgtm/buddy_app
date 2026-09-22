import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auth_state.dart';
import '../../viewmodels/splash_view_model.dart';
import '../registration/registration_flow_page.dart';
import '../widgets/gabby_mascot_widget.dart';
import '../widgets/neo_background.dart';
import '../widgets/slide_to_action.dart';

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
      backgroundColor: const Color(0xFFFBF8EE),
      body: NeoBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Top GabbyTalk Brand Logo Header
                    _buildTopLogoHeader(),

                    const Spacer(flex: 2),

                    // Center Animated Gabby Mascot with Telephone Handset
                    const GabbyMascotWidget(
                      pose: MascotPose.phoneCall,
                      size: 220,
                    ),

                    const Spacer(flex: 2),

                    // Title & Tagline
                    Text(
                      'YOUR VOICE, YOUR FRIENDS! 🎙️',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Real People • Meaningful Conversations',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Rainbow Candy Slide to Action Button
                    _buildRainbowSlideButton(),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopLogoHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Circular Gabby Speech Bubble Icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.strokeBlack,
              width: 2.2,
            ),
            boxShadow: AppTheme.neoShadow(offset: const Offset(2.0, 2.0)),
          ),
          child: const Center(
            child: Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // GabbyTalk Two-Tone Typography
        RichText(
          text: TextSpan(
            style: AppTypography.brandLogo.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
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

  Widget _buildRainbowSlideButton() {
    return SlideToActionButton(
      text: '>>>> SLIDE TO BEGIN TALK <<<<',
      icon: Icons.phone_rounded,
      backgroundColor: const Color(0xFF1E293B),
      handleColor: const Color(0xFF38BDF8),
      textColor: Colors.white,
      iconColor: Colors.white,
      height: 64.0,
      onCompleted: _onSlideToGetStarted,
    );
  }
}
