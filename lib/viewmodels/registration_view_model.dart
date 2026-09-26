import 'dart:async';
import '../core/network/api_exceptions.dart';
import '../core/network/token_manager.dart';
import '../data/models/auth_state.dart';
import '../data/models/interest_model.dart';
import '../data/models/user_profile.dart';
import '../data/models/user_role.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import 'base_view_model.dart';

class RegistrationViewModel extends BaseViewModel {
  final IAuthRepository _authRepository;
  final IUserRepository _userRepository;

  AuthFlowMode _flowMode;
  RegistrationStep _currentStep = RegistrationStep.phoneNumber;

  // Step 1: Phone
  String _countryCode = '+91';
  String _phoneNumber = '';
  final List<String> _availableCountryCodes = [
    '+91',
    '+1',
    '+44',
    '+61',
    '+49',
    '+33',
    '+81',
  ];

  // Step 2: OTP
  String _otpCode = '';
  int _resendCountdown = 30;
  Timer? _countdownTimer;
  bool _canResend = false;

  // Step 3: First Details & Interests
  String _firstName = '';
  int? _age;
  Gender _selectedGender = Gender.woman;
  List<String> _selectedInterests = [];

  RegistrationViewModel({
    required IAuthRepository authRepository,
    required IUserRepository userRepository,
    AuthFlowMode initialMode = AuthFlowMode.login,
  }) : _authRepository = authRepository,
       _userRepository = userRepository,
       _flowMode = initialMode;

  // Getters
  AuthFlowMode get flowMode => _flowMode;
  bool get isLoginMode => _flowMode == AuthFlowMode.login;
  RegistrationStep get currentStep => _currentStep;
  int get stepIndex => _currentStep.stepIndex;

  String get countryCode => _countryCode;
  String get phoneNumber => _phoneNumber;
  List<String> get availableCountryCodes => _availableCountryCodes;
  String get fullDisplayPhone => '$_countryCode $_phoneNumber';

  String get otpCode => _otpCode;
  int get resendCountdown => _resendCountdown;
  bool get canResend => _canResend;

  String get firstName => _firstName;
  int? get age => _age;
  Gender get selectedGender => _selectedGender;
  List<String> get selectedInterests => _selectedInterests;
  List<String> get availableInterests =>
      defaultInterestsList.map((i) => i.displayTag).toList();
  bool get isAgent =>
      _authRepository.currentRole == UserRole.agent ||
      _authRepository.currentUser?.isAgent == true;

  // Step 1: Phone methods
  void setCountryCode(String code) {
    _countryCode = code;
    notifyListenersSafely();
  }

  void setPhoneNumber(String number) {
    _phoneNumber = number.trim();
    clearError();
    notifyListenersSafely();
  }

  bool get isPhoneValid =>
      _phoneNumber.replaceAll(RegExp(r'\D'), '').length == 10;

  Future<bool> submitPhoneNumber() async {
    if (!isPhoneValid) {
      setError('Please enter a valid 10-digit phone number');
      return false;
    }

    setLoading(true);
    clearError();
    try {
      final success = await _authRepository.sendOtp(
        countryCode: _countryCode,
        phoneNumber: _phoneNumber,
        isLogin: isLoginMode,
      );
      if (success) {
        _currentStep = RegistrationStep.otpVerification;
        startResendTimer();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      final msg = e.toString().replaceFirst(
        RegExp(r'^[A-Za-z0-9_]*Exception:\s*'),
        '',
      );
      setError(msg);
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Step 2: OTP methods
  void setOtpCode(String code) {
    _otpCode = code;
    clearError();
    notifyListenersSafely();
  }

  void startResendTimer() {
    _countdownTimer?.cancel();
    _resendCountdown = 30;
    _canResend = false;
    notifyListenersSafely();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        _resendCountdown--;
        notifyListenersSafely();
      } else {
        _canResend = true;
        _resendCountdown = 0;
        timer.cancel();
        notifyListenersSafely();
      }
    });
  }

  Future<bool> resendOtp() async {
    if (!_canResend) return false;
    setLoading(true);
    try {
      await _authRepository.sendOtp(
        countryCode: _countryCode,
        phoneNumber: _phoneNumber,
        isLogin: isLoginMode,
      );
      startResendTimer();
      return true;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      setError(
        e.toString().replaceFirst(RegExp(r'^[A-Za-z0-9_]*Exception:\s*'), ''),
      );
      return false;
    } finally {
      setLoading(false);
    }
  }

  void setFlowMode(AuthFlowMode mode) {
    _flowMode = mode;
    _currentStep = RegistrationStep.phoneNumber;
    clearError();
    notifyListenersSafely();
  }

  void toggleFlowMode() {
    setFlowMode(
      _flowMode == AuthFlowMode.login
          ? AuthFlowMode.signUp
          : AuthFlowMode.login,
    );
  }

  bool get isOtpValid =>
      _otpCode.trim().length >= 4 && _otpCode.trim().length <= 6;

  Future<bool> submitOtp() async {
    if (!isOtpValid) {
      setError('Please enter the complete verification code');
      return false;
    }

    setLoading(true);
    clearError();
    try {
      final cleanDigits = _phoneNumber.replaceAll(RegExp(r'\D'), '');
      final fullPhone = _phoneNumber.startsWith('+')
          ? _phoneNumber
          : '$_countryCode$cleanDigits';

      final success = await _authRepository.verifyOtp(
        phoneNumber: fullPhone,
        otpCode: _otpCode,
        isLogin: isLoginMode,
      );
      if (success) {
        _countdownTimer?.cancel();

        final user = _authRepository.currentUser;
        final hasName =
            user?.firstName != null &&
            user!.firstName.trim().isNotEmpty &&
            user.firstName.trim().toLowerCase() != 'null';
        final isComplete =
            _authRepository.isProfileCompleted &&
            hasName &&
            !_authRepository.isNewUser;

        if (isAgent || (isLoginMode && isComplete)) {
          // In login flow for existing registered user or agent: proceed immediately to completed / dashboard
          _currentStep = RegistrationStep.completed;
        } else {
          // In signup flow OR login with new/unregistered number: proceed to profile details signup view
          _flowMode = AuthFlowMode.signUp;
          _currentStep = RegistrationStep.firstDetails;
        }
        notifyListenersSafely();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      final msg = e.toString().replaceFirst(
        RegExp(r'^[A-Za-z0-9_]*Exception:\s*'),
        '',
      );
      setError(msg);
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Step 3: First Details methods
  void setFirstName(String name) {
    _firstName = name;
    clearError();
    notifyListenersSafely();
  }

  void setAge(String ageStr) {
    final parsed = int.tryParse(ageStr.trim());
    _age = parsed;
    clearError();
    notifyListenersSafely();
  }

  void setGender(Gender gender) {
    _selectedGender = gender;
    notifyListenersSafely();
  }

  String _formatGender(Gender gender) {
    switch (gender) {
      case Gender.woman:
        return 'Female';
      case Gender.man:
        return 'Male';
      case Gender.nonBinary:
        return 'Female';
    }
  }

  void toggleInterest(String interest) {
    if (_selectedInterests.contains(interest)) {
      _selectedInterests.remove(interest);
    } else {
      _selectedInterests.add(interest);
    }
    notifyListenersSafely();
  }

  void setSelectedInterests(List<String> interests) {
    _selectedInterests = List.from(interests);
    notifyListenersSafely();
  }

  Future<bool> completeRegistration() => submitFirstDetails();

  Future<bool> submitFirstDetails() async {
    if (_firstName.trim().isEmpty) {
      setError('Please enter your first name');
      return false;
    }
    if (_age == null || _age! < 17 || _age! > 99) {
      setError('Please enter an age of 18 or above');
      return false;
    }

    setLoading(true);
    clearError();
    try {
      //  await TokenManager().getAccessToken();

      // if (token == null || token.isEmpty) {
      //   setError(
      //     'Verification token is missing. Please verify your phone number again.',
      //   );
      //   return false;
      final cleanDigits = _phoneNumber.replaceAll(RegExp(r'\D'), '');
      final fullPhone = _phoneNumber.startsWith('+')
          ? _phoneNumber
          : '$_countryCode$cleanDigits';

      final success = await _authRepository.completeCallerProfile(
        // verificationToken: token,
        name: _firstName.trim(),
        age: _age ?? 20,
        gender: _formatGender(_selectedGender),
        language: 'English',
        phoneNumber: fullPhone.isNotEmpty
            ? fullPhone
            : (_phoneNumber.isNotEmpty ? _phoneNumber : null),
      );

      if (success) {
        _currentStep = RegistrationStep.completed;
        notifyListenersSafely();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      setError(e.message);
      return false;
    } catch (e) {
      final msg = e.toString().replaceFirst(
        RegExp(r'^[A-Za-z0-9_]*Exception:\s*'),
        '',
      );
      setError(msg);
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Step navigation
  bool goBack() {
    if (_currentStep == RegistrationStep.phoneNumber) {
      return true; // Pop screen
    } else if (_currentStep == RegistrationStep.otpVerification) {
      _countdownTimer?.cancel();
      _otpCode = '';
      _currentStep = RegistrationStep.phoneNumber;
    } else if (_currentStep == RegistrationStep.firstDetails) {
      // Once OTP is verified and user is on profile details, going back skips OTP screen
      _countdownTimer?.cancel();
      _otpCode = '';
      _currentStep = RegistrationStep.phoneNumber;
    }
    notifyListenersSafely();
    return false;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
