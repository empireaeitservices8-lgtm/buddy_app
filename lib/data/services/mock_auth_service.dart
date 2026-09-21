import '../models/user_role.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';

class MockAuthService implements IAuthRepository {
  UserRole? _role = UserRole.user;
  UserProfile? _user;
  String _lastGeneratedOtp = '1234';
  String? _verificationToken;

  @override
  UserRole? get currentRole => _role;

  @override
  UserProfile? get currentUser => _user;

  @override
  String? get verificationToken => _verificationToken;

  @override
  bool get isNewUser => _user?.firstName == null || _user!.firstName.isEmpty;

  @override
  bool get isProfileCompleted =>
      _user?.firstName != null && _user!.firstName.isNotEmpty;

  String get lastGeneratedOtp => _lastGeneratedOtp;

  void setRole(UserRole role) {
    _role = role;
  }

  @override
  Future<bool> sendOtp({
    required String countryCode,
    required String phoneNumber,
    bool isLogin = false,
  }) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 600));
    _user = UserProfile(countryCode: countryCode, phoneNumber: phoneNumber);
    _lastGeneratedOtp = '1234'; // Default mock code
    return true;
  }

  @override
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    bool isLogin = false,
    String? fcmToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Accepts 1234 or any 4 digit code in mock environment
    if (otpCode.length == 4) {
      _verificationToken =
          'mock_verification_token_${DateTime.now().millisecondsSinceEpoch}';
      return true;
    }
    return false;
  }

  @override
  Future<bool> completeCallerProfile({
    // required String verificationToken,
    required String name,
    required int age,
    required String gender,
    String? language,
    String? fcmToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _role = UserRole.user;
    _user =
        _user?.copyWith(
          firstName: name,
          age: age,
          gender: Gender.fromString(gender),
          language: language ?? 'English',
        ) ??
        UserProfile(
          firstName: name,
          age: age,
          gender: Gender.fromString(gender),
          language: language ?? 'English',
        );
    return true;
  }

  @override
  Future<bool> agentLogin({
    required String username,
    required String password,
    String? fcmToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (username.trim().isNotEmpty && password.isNotEmpty) {
      _role = UserRole.agent;
      _user = UserProfile(
        firstName: username,
        countryCode: '+1',
        phoneNumber: '800-BUDDY',
      );
      return true;
    }
    return false;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _user = null;
    _role = UserRole.user;
    _verificationToken = null;
  }
}
