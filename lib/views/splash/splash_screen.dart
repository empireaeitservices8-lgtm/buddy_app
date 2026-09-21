import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/token_manager.dart';
import '../../core/services/fcm_service.dart';
import '../../core/theme/app_theme.dart';
import '../agent/agent_dashboard_screen.dart';
import '../home/home_dashboard_screen.dart';
import '../welcome/welcome_screen.dart';
import '../widgets/sparkle_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Initialize TokenManager and verify stored token in SharedPreferences
      await TokenManager().init();
      final hasToken = await TokenManager().hasToken();
      final token = await TokenManager().getAccessToken();
      final role = await TokenManager().getUserRole();

      // Retrieve or ensure FCM Device Token is initialized
      final fcmToken = await FcmService.getFcmToken();
      debugPrint(
        '🔥 [SplashScreen] FCM Device Token: ${fcmToken ?? "Unavailable/Pending"}',
      );

      // Proactively sync fresh FCM token to backend on app startup if logged in
      if (hasToken) {
        FcmService.sendFcmTokenToBackend(fcmToken);
      }

      debugPrint(
        '🔍 [SplashScreen] Stored token check: hasToken=$hasToken, role=$role (token: ${token != null ? "${token.substring(0, token.length > 8 ? 8 : token.length)}..." : "null"})',
      );

      // Show splash animation for at least 1.0 second for a smooth branded experience
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      if (hasToken) {
        final isAgent = role?.toLowerCase() == 'agent';
        final Widget targetScreen = isAgent
            ? const AgentDashboardScreen()
            : const HomeDashboardScreen();

        debugPrint(
          '🚀 [SplashScreen] Valid token found -> Navigating directly to ${isAgent ? "AgentDashboardScreen" : "HomeDashboardScreen"}',
        );
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                targetScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => false,
        );
      } else {
        debugPrint(
          '👉 [SplashScreen] No token found -> Navigating to WelcomeScreen',
        );
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const WelcomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ [SplashScreen] Auth check error: $e');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
            child: Stack(
              children: [
                // Decorative Sparkles
                const Positioned(
                  top: 50,
                  left: 32,
                  child: SparkleWidget(size: 28, color: AppColors.strokeBlack),
                ),
                const Positioned(
                  top: 90,
                  right: 40,
                  child: SparkleWidget(
                    size: 22,
                    color: AppColors.accentLavender,
                  ),
                ),
                const Positioned(
                  bottom: 120,
                  left: 40,
                  child: SparkleWidget(size: 24, color: AppColors.accentPink),
                ),
                const Positioned(
                  bottom: 180,
                  right: 36,
                  child: SparkleWidget(size: 30, color: AppColors.strokeBlack),
                ),

                // Center Branding & Loading Indicator
                Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Icon
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
                                offset: const Offset(5, 5),
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
                          const SizedBox(height: 28),

                          // App Title
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
                          const SizedBox(height: 12),

                          // Tagline Badge
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
                          const SizedBox(height: 48),

                          // Animated Neo Loading Indicator
                          Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.strokeBlack,
                                width: 2.0,
                              ),
                              boxShadow: AppTheme.neoShadow(
                                offset: const Offset(2, 2),
                              ),
                            ),
                            child: const CircularProgressIndicator(
                              strokeWidth: 3.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF00A79D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
