import 'package:flutter/material.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/cartoon_theme.dart';
import '../../data/models/auth_state.dart';
import '../../viewmodels/splash_view_model.dart';
import '../registration/registration_flow_page.dart';
import '../widgets/gabby_mascot_widget.dart';
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSmallScreen = screenHeight < 680;
    final mascotSize = (screenHeight * 0.25).clamp(110.0, 200.0);

    return CartoonScaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Top GabbyTalk Brand Logo Header
                        _buildTopLogoHeader(),

                        const Spacer(),

                        // Center Animated Mascot inside dark-bordered circular cartoon container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CartoonColors.cardWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CartoonColors.charcoal,
                              width: CartoonTheme.borderWidth,
                            ),
                            boxShadow: CartoonTheme.shadow(offset: const Offset(4, 4)),
                          ),
                          child: GabbyMascotWidget(
                            pose: MascotPose.phoneCall,
                            size: mascotSize,
                          ),
                        ),

                        const Spacer(),

                        // Title & Tagline
                        Text(
                          'YOUR VOICE, YOUR FRIENDS! 🎙️',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: CartoonColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Real People • Meaningful Conversations',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: CartoonColors.textMuted,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Rounded Neubrutal slider control
                        _buildRainbowSlideButton(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopLogoHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Circular Gabby Speech Bubble Icon
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: CartoonColors.sky,
            shape: BoxShape.circle,
            border: Border.all(
              color: CartoonColors.charcoal,
              width: CartoonTheme.borderWidth,
            ),
            boxShadow: CartoonTheme.shadow(offset: const Offset(2.5, 2.5)),
          ),
          child: const Center(
            child: Icon(
              Icons.graphic_eq_rounded,
              color: CartoonColors.charcoal,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // GabbyTalk High-Contrast Typography
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              fontFamily: 'Roboto',
            ),
            children: [
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
      text: 'SLIDE TO BEGIN TALKING',
      icon: Icons.phone_rounded,
      backgroundColor: CartoonColors.charcoal,
      handleColor: CartoonColors.lime,
      textColor: Colors.white,
      iconColor: CartoonColors.charcoal,
      height: 64.0,
      onCompleted: _onSlideToGetStarted,
    );
  }
}
