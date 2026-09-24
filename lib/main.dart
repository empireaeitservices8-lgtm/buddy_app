import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_strings.dart';
import 'core/navigation/navigation_service.dart';
import 'core/network/token_manager.dart';
import 'core/services/fcm_service.dart';
import 'core/services/incoming_call_manager.dart';
import 'core/theme/app_theme.dart';
import 'views/splash/splash_screen.dart';
import 'views/widgets/global_incoming_call_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local token storage
  await TokenManager().init();

  // Initialize Firebase and Firebase Cloud Messaging (FCM)
  await FcmService.initialize();

  // Initialize Global Incoming Call Manager for agents
  IncomingCallManager.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const BuddyApp());
}

class BuddyApp extends StatelessWidget {
  const BuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      builder: (context, child) {
        return GlobalIncomingCallOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
