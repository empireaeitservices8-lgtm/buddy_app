import '../models/user_role.dart';
import '../models/user_profile.dart';

abstract class IAuthRepository {
  Future<bool> sendOtp({
    required String countryCode,
    required String phoneNumber,
    bool isLogin = false,
  });
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    bool isLogin = false,
    String? fcmToken,
  });
  Future<bool> completeCallerProfile({
    // required String verificationToken,
    required String name,
    required int age,
    required String gender,

    String? language,
    String? fcmToken,
  });
  Future<bool> agentLogin({
    required String username,
    required String password,
    String? fcmToken,
  });
  Future<void> logout();
  UserRole? get currentRole;
  UserProfile? get currentUser;
  String? get verificationToken;
  bool get isNewUser;
  bool get isProfileCompleted;
}
