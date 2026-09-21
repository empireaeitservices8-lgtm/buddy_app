import 'package:flutter/material.dart';
import '../../views/splash/splash_screen.dart';
import '../../views/welcome/welcome_screen.dart';
import '../../views/widgets/toast_utils.dart';
import '../network/token_manager.dart';

/// Global Navigation Service providing context-independent navigation
/// across the application, especially for unauthenticated / 401 session expiry and 404 error handling.
class NavigationService {
  NavigationService._();

  /// Global navigator key registered on the root [MaterialApp]
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _isNavigatingToSplash = false;
  static bool _isNavigatingToWelcome = false;

  /// Current build context if available in the widget tree
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Globally redirects to the Splash screen upon unauthenticated session expiration.
  ///
  /// Clears stored tokens and flushes the entire navigation stack to prevent
  /// unauthenticated back-navigation.
  static Future<void> navigateToSplash({String? reason}) async {
    if (_isNavigatingToSplash) return;
    _isNavigatingToSplash = true;

    // Purge stored authentication tokens immediately
    try {
      await TokenManager().clearTokens();
    } catch (_) {}

    final context = navigatorKey.currentContext;
    if (context != null && reason != null && reason.isNotEmpty) {
      // ignore: use_build_context_synchronously
      showNeoToast(context, reason, isError: true);
    }

    // Schedule navigation safely on the next microtask/frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        ),
        (route) => false,
      );

      // Reset throttle lock after page transition completes
      Future.delayed(const Duration(milliseconds: 600), () {
        _isNavigatingToSplash = false;
      });
    });
  }

  /// Backward-compatible alias for unauthenticated navigation
  static Future<void> navigateToLogin({String? reason}) =>
      navigateToSplash(reason: reason);

  /// Globally redirects to the Welcome screen upon encountering HTTP 404 (Not Found).
  static Future<void> navigateToWelcome({String? reason}) async {
    if (_isNavigatingToWelcome) return;
    _isNavigatingToWelcome = true;

    // Purge stored authentication tokens
    try {
      await TokenManager().clearTokens();
    } catch (_) {}

    final context = navigatorKey.currentContext;
    if (context != null && reason != null && reason.isNotEmpty) {
      // ignore: use_build_context_synchronously
      showNeoToast(context, reason, isError: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );

      // Reset throttle lock after page transition completes
      Future.delayed(const Duration(milliseconds: 600), () {
        _isNavigatingToWelcome = false;
      });
    });
  }
}

