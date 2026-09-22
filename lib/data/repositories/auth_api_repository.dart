import 'dart:convert';
import 'package:buddy_app/core/network/api_response.dart';
import 'package:dio/dio.dart';
import 'package:buddy_app/core/network/token_manager.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/api_service.dart';
import '../../core/services/fcm_service.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import 'auth_repository.dart';

/// Production implementation of [IAuthRepository] interacting with the live backend.
class AuthApiRepository implements IAuthRepository {
  final ApiService _apiService;
  UserRole? _currentRole;
  UserProfile? _currentUser;

  AuthApiRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  @override
  UserRole? get currentRole {
    if (_currentRole != null) return _currentRole;
    final roleStr = TokenManager().userRoleSync;
    if (roleStr != null && roleStr.isNotEmpty) {
      if (roleStr == UserRole.agent.name || roleStr == 'agent') {
        _currentRole = UserRole.agent;
      } else {
        _currentRole = UserRole.user;
      }
    }
    return _currentRole;
  }

  @override
  UserProfile? get currentUser {
    if (_currentUser != null) return _currentUser;
    final userDataStr = TokenManager().userDataSync;
    if (userDataStr != null && userDataStr.isNotEmpty) {
      try {
        final map = jsonDecode(userDataStr) as Map<String, dynamic>;
        if (currentRole == UserRole.agent) {
          _currentUser = UserProfile(
            id: map['id']?.toString(),
            userId: map['id']?.toString(),
            firstName:
                map['display_name']?.toString() ??
                map['name']?.toString() ??
                map['first_name']?.toString() ??
                map['username']?.toString() ??
                map['listener_id']?.toString() ??
                'Listener',
            language: map['language']?.toString(),
            isOnline: map['is_available'] == true,
          );
        } else {
          _currentUser = UserProfile.fromJson(map);
        }
      } catch (_) {}
    }
    return _currentUser;
  }

  String? _verificationToken;
  bool _isNewUser = false;
  bool _isProfileCompleted = false;

  @override
  String? get verificationToken => _verificationToken;

  @override
  bool get isNewUser => _isNewUser;

  @override
  bool get isProfileCompleted => _isProfileCompleted;

  @override
  Future<bool> sendOtp({
    required String countryCode,
    required String phoneNumber,
    bool isLogin = false,
  }) async {
    try {
      final cleanDigits = phoneNumber.trim().replaceAll(RegExp(r'\D'), '');
      final cleanCountry = countryCode.trim().startsWith('+')
          ? countryCode.trim()
          : '+${countryCode.trim()}';

      final fullPhoneNumber = phoneNumber.trim().startsWith('+')
          ? phoneNumber.trim()
          : '$cleanCountry$cleanDigits';

      if (isLogin) {
        _isNewUser = false;
      } else {
        _isNewUser = true;
      }

      final endpoint = isLogin
          ? ApiConstants.callerLoginSendOtp
          : ApiConstants.callerSignupSendOtp;

      ApiResponse response;
      try {
        response = await _apiService.post(
          endpoint,
          data: {'phone_number': fullPhoneNumber},
          requiresAuth: false,
        );
      } on ApiException catch (_) {
        // If login send-otp fails (e.g. 404 user not found), fallback to signup send-otp automatically
        if (isLogin) {
          _isNewUser = true;
          response = await _apiService.post(
            ApiConstants.callerSignupSendOtp,
            data: {'phone_number': fullPhoneNumber},
            requiresAuth: false,
          );
        } else {
          rethrow;
        }
      }

      if (response.rawData is Map && response.rawData['success'] == false) {
        if (isLogin) {
          _isNewUser = true;
          final signupResponse = await _apiService.post(
            ApiConstants.callerSignupSendOtp,
            data: {'phone_number': fullPhoneNumber},
            requiresAuth: false,
          );
          if (signupResponse.isSuccess) {
            _currentUser = UserProfile(
              countryCode: cleanCountry,
              phoneNumber: cleanDigits,
            );
            return true;
          }
        }
        final errorMsg =
            response.rawData['message']?.toString() ??
            response.message ??
            'Failed to send OTP';
        throw BadRequestException(
          message: errorMsg,
          statusCode: response.statusCode,
        );
      }

      if (!response.isSuccess) {
        final errorMsg = response.message ?? 'Failed to send OTP';
        throw BadRequestException(
          message: errorMsg,
          statusCode: response.statusCode,
        );
      }

      _currentUser = UserProfile(
        countryCode: cleanCountry,
        phoneNumber: cleanDigits,
      );

      return true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnexpectedException(message: 'Failed to send OTP: $e');
    }
  }

  @override
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    bool isLogin = false,
    String? fcmToken,
  }) async {
    try {
      final cleanDigits = phoneNumber.trim().replaceAll(RegExp(r'\D'), '');
      final fullPhoneNumber = phoneNumber.trim().startsWith('+')
          ? phoneNumber.trim()
          : '+$cleanDigits';

      final endpoint = (isLogin && !_isNewUser)
          ? ApiConstants.callerLoginVerifyOtp
          : ApiConstants.callerSignupVerifyOtp;

      final effectiveFcmToken =
          fcmToken ??
          await FcmService.getFcmToken() ??
          await _apiService.tokenManager.getFcmToken();

      final requestData = <String, dynamic>{
        'phone_number': fullPhoneNumber,
        'otp': otpCode.trim(),
        if (effectiveFcmToken != null && effectiveFcmToken.isNotEmpty)
          'fcm_token': effectiveFcmToken,
      };

      ApiResponse response;
      try {
        response = await _apiService.post(
          endpoint,
          data: requestData,
          requiresAuth: false,
        );
      } on ApiException {
        if (isLogin) {
          response = await _apiService.post(
            ApiConstants.callerSignupVerifyOtp,
            data: requestData,
            requiresAuth: false,
          );
        } else {
          rethrow;
        }
      }

      if (response.rawData is Map && response.rawData['success'] == false) {
        if (isLogin) {
          final signupResponse = await _apiService.post(
            ApiConstants.callerSignupVerifyOtp,
            data: requestData,
            requiresAuth: false,
          );
          if (signupResponse.isSuccess) {
            response = signupResponse;
          } else {
            final errorMsg =
                response.rawData['message']?.toString() ??
                response.message ??
                'Invalid verification code. Please check and retry.';
            throw BadRequestException(
              message: errorMsg,
              statusCode: response.statusCode,
            );
          }
        } else {
          final errorMsg =
              response.rawData['message']?.toString() ??
              response.message ??
              'Invalid verification code. Please check and retry.';
          throw BadRequestException(
            message: errorMsg,
            statusCode: response.statusCode,
          );
        }
      }

      if (response.isSuccess) {
        if (response.rawData is Map) {
          final raw = response.rawData as Map<String, dynamic>;
          final innerData = raw['data'] is Map
              ? raw['data'] as Map<String, dynamic>
              : raw;

          final userJson = innerData['user'] is Map
              ? innerData['user'] as Map<String, dynamic>
              : null;

          final bool isAgent =
              innerData['is_agent'] == true ||
              raw['is_agent'] == true ||
              (userJson != null &&
                  (userJson['is_agent'] == true ||
                      userJson['role']?.toString().toUpperCase() == 'AGENT')) ||
              innerData['role']?.toString().toUpperCase() == 'AGENT' ||
              raw['role']?.toString().toUpperCase() == 'AGENT';

          final role = isAgent ? UserRole.agent : UserRole.user;
          _currentRole = role;

          final bool explicitNewUser =
              innerData['is_new_user'] == true ||
              raw['is_new_user'] == true ||
              innerData['is_new'] == true ||
              raw['is_new'] == true ||
              innerData['is_registered'] == false ||
              raw['is_registered'] == false ||
              innerData['profile_completed'] == false ||
              raw['profile_completed'] == false;

          final rawUserId =
              innerData['user_id'] ??
              raw['user_id'] ??
              innerData['id'] ??
              raw['id'] ??
              (userJson != null
                  ? (userJson['id'] ?? userJson['user_id'])
                  : null);

          // Save user object if present (e.g. In login responses)
          if (userJson != null) {
            final parsedProfile = UserProfile.fromJson(userJson);
            _currentUser = parsedProfile.copyWith(
              phoneNumber: (parsedProfile.phoneNumber != null &&
                      parsedProfile.phoneNumber!.isNotEmpty)
                  ? parsedProfile.phoneNumber
                  : (cleanDigits.isNotEmpty ? cleanDigits : phoneNumber),
            );
            try {
              final toSave = Map<String, dynamic>.from(userJson);
              if (!toSave.containsKey('phone_number') ||
                  toSave['phone_number'] == null ||
                  toSave['phone_number'].toString().isEmpty) {
                toSave['phone_number'] =
                    cleanDigits.isNotEmpty ? cleanDigits : phoneNumber;
              }
              await _apiService.tokenManager.saveUserData(jsonEncode(toSave));
              await _apiService.tokenManager.saveUserRole(role.name);
            } catch (_) {}
          } else {
            _currentUser = UserProfile(
              id: rawUserId?.toString() ?? '',
              userId: rawUserId?.toString() ?? '',
              phoneNumber: cleanDigits.isNotEmpty ? cleanDigits : phoneNumber,
              countryCode: _currentUser?.countryCode ?? '+91',
            );
            try {
              await _apiService.tokenManager.saveUserData(
                jsonEncode({
                  if (rawUserId != null) 'id': rawUserId,
                  if (rawUserId != null) 'user_id': rawUserId,
                  'phone_number': cleanDigits.isNotEmpty ? cleanDigits : phoneNumber,
                }),
              );
              await _apiService.tokenManager.saveUserRole(role.name);
            } catch (_) {}
          }

          // Save tokens
          String? accessToken;
          String? refreshToken;

          if (innerData['tokens'] is Map) {
            final tokensMap = innerData['tokens'] as Map<String, dynamic>;
            accessToken =
                tokensMap['access'] as String? ??
                tokensMap['access_token'] as String? ??
                tokensMap['token'] as String?;
            refreshToken =
                tokensMap['refresh'] as String? ??
                tokensMap['refresh_token'] as String?;
          } else if (raw['tokens'] is Map) {
            final tokensMap = raw['tokens'] as Map<String, dynamic>;
            accessToken =
                tokensMap['access'] as String? ??
                tokensMap['access_token'] as String? ??
                tokensMap['token'] as String?;
            refreshToken =
                tokensMap['refresh'] as String? ??
                tokensMap['refresh_token'] as String?;
          } else {
            accessToken =
                innerData['access'] as String? ??
                innerData['access_token'] as String? ??
                innerData['token'] as String? ??
                raw['access'] as String? ??
                raw['access_token'] as String? ??
                raw['token'] as String?;
            refreshToken =
                innerData['refresh'] as String? ??
                innerData['refresh_token'] as String? ??
                raw['refresh'] as String? ??
                raw['refresh_token'] as String?;
          }

          final verificationToken =
              innerData['verification_token'] as String? ??
              raw['verification_token'] as String? ??
              accessToken;

          if (verificationToken != null && verificationToken.isNotEmpty) {
            _verificationToken = verificationToken;
            if (_apiService.tokenManager is TokenManager) {
              await (_apiService.tokenManager as TokenManager)
                  .saveVerificationToken(verificationToken);
            }
          }

          if (accessToken != null && accessToken.isNotEmpty) {
            await _apiService.tokenManager.saveTokens(
              accessToken: accessToken,
              refreshToken: refreshToken,
            );
            await _apiService.tokenManager.saveUserRole(role.name);
            FcmService.sendFcmTokenToBackend();
          }

          final hasValidName =
              _currentUser?.firstName != null &&
              _currentUser!.firstName.trim().isNotEmpty &&
              _currentUser!.firstName.trim().toLowerCase() != 'null';

          _isNewUser = explicitNewUser || !hasValidName;
          _isProfileCompleted = !_isNewUser && hasValidName;
        }
        return true;
      }
      return false;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnexpectedException(message: 'Failed to verify OTP: $e');
    }
  }

  @override
  Future<bool> completeCallerProfile({
    // required String verificationToken,
    required String name,
    required int age,
    required String gender,
    String? phoneNumber,
    String? language,
    String? fcmToken,
  }) async {
    try {
      final effectiveFcmToken =
          fcmToken ??
          await FcmService.getFcmToken() ??
          await _apiService.tokenManager.getFcmToken();

      final stored =
          await _apiService.tokenManager.getAccessToken() ??
          await (_apiService.tokenManager is TokenManager
              ? (_apiService.tokenManager as TokenManager)
                    .getVerificationToken()
              : null);
      if (stored != null && stored.isNotEmpty) {
        stored
            .trim()
            .replaceAll('Bearer ', '')
            .replaceAll('"', '')
            .replaceAll("'", '')
            .trim();
      }

      int? parsedUserId;
      final resolvedUserId =
          _currentUser?.userId ??
          _currentUser?.id ??
          currentUser?.userId ??
          currentUser?.id;
      if (resolvedUserId != null) {
        parsedUserId = int.tryParse(resolvedUserId.toString());
      }

      String? resolvedPhone = phoneNumber ??
          _currentUser?.phoneNumber ??
          currentUser?.phoneNumber;

      if (parsedUserId == null || resolvedPhone == null || resolvedPhone.isEmpty) {
        final storedUserData = await _apiService.tokenManager.getUserData();
        if (storedUserData != null && storedUserData.isNotEmpty) {
          try {
            final map = jsonDecode(storedUserData) as Map<String, dynamic>;
            final rawId =
                map['user_id'] ??
                map['id'] ??
                map['user']?['id'] ??
                map['user']?['user_id'];
            if (parsedUserId == null && rawId != null) {
              parsedUserId = int.tryParse(rawId.toString());
            }
            if (resolvedPhone == null || resolvedPhone.isEmpty) {
              final rawPhone = map['phone_number'] ??
                  map['phone'] ??
                  map['mobile'] ??
                  map['user']?['phone_number'] ??
                  map['user']?['phone'];
              if (rawPhone != null && rawPhone.toString().isNotEmpty) {
                resolvedPhone = rawPhone.toString();
              }
            }
          } catch (_) {}
        }
      }

      if (parsedUserId == null || resolvedPhone == null || resolvedPhone.isEmpty) {
        try {
          final parts = stored!.split('.');
          if (parts.length == 3) {
            final normalized = base64Url.normalize(parts[1]);
            final payloadStr = utf8.decode(base64Url.decode(normalized));
            final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
            final jwtUserId = payload['user_id'] ?? payload['id'];
            if (parsedUserId == null && jwtUserId != null) {
              parsedUserId = int.tryParse(jwtUserId.toString());
            }
            if (resolvedPhone == null || resolvedPhone.isEmpty) {
              final jwtPhone = payload['phone_number'] ?? payload['phone'];
              if (jwtPhone != null && jwtPhone.toString().isNotEmpty) {
                resolvedPhone = jwtPhone.toString();
              }
            }
          }
        } catch (_) {}
      }

      final requestData = <String, dynamic>{
        if (parsedUserId != null)
          'user_id': parsedUserId
        else if (resolvedUserId != null && resolvedUserId.isNotEmpty)
          'user_id': resolvedUserId,
        if (resolvedPhone != null && resolvedPhone.isNotEmpty)
          'phone_number': resolvedPhone,
        'name': name.trim(),
        'age': age,
        'gender': gender.trim(),
        if (language != null && language.isNotEmpty) 'language': language,
        if (effectiveFcmToken != null && effectiveFcmToken.isNotEmpty)
          'fcm_token': effectiveFcmToken,
      };

      final response = await _apiService.post(
        ApiConstants.callerCompleteProfile,
        data: requestData,
        requiresAuth: false,
      );

      if (response.rawData is Map && response.rawData['success'] == false) {
        final errorMsg =
            response.rawData['message']?.toString() ??
            response.message ??
            'Failed to complete profile';
        throw BadRequestException(
          message: errorMsg,
          statusCode: response.statusCode,
        );
      }

      if (response.isSuccess && response.rawData is Map) {
        final raw = response.rawData as Map<String, dynamic>;
        final data = raw['data'] is Map
            ? raw['data'] as Map<String, dynamic>
            : raw;

        // Save User Profile
        final userJson = data['user'] is Map
            ? data['user'] as Map<String, dynamic>
            : (raw['user'] is Map ? raw['user'] as Map<String, dynamic> : null);

        if (userJson != null) {
          _currentUser = UserProfile.fromJson(userJson);
          _currentRole = UserRole.user;
          _isNewUser = false;
          _isProfileCompleted = true;
          try {
            await _apiService.tokenManager.saveUserData(jsonEncode(userJson));
            await _apiService.tokenManager.saveUserRole(UserRole.user.name);
          } catch (_) {}
        } else {
          final fallbackUserId =
              parsedUserId?.toString() ??
              data['user_id']?.toString() ??
              raw['user_id']?.toString() ??
              _currentUser?.userId;

          _currentUser = (_currentUser ?? const UserProfile()).copyWith(
            id: fallbackUserId,
            userId: fallbackUserId,
            firstName: name.trim(),
            age: age,
            gender: Gender.fromString(gender),
            language: language ?? 'English',
          );
          _currentRole = UserRole.user;
          _isNewUser = false;
          _isProfileCompleted = true;
          try {
            await _apiService.tokenManager.saveUserData(
              jsonEncode(_currentUser!.toJson()),
            );
            await _apiService.tokenManager.saveUserRole(UserRole.user.name);
          } catch (_) {}
        }

        // Save Access & Refresh Tokens to SharedPreferences
        String? accessToken;
        String? refreshToken;

        if (data['tokens'] is Map) {
          final tokensMap = data['tokens'] as Map<String, dynamic>;
          accessToken =
              tokensMap['access'] as String? ??
              tokensMap['access_token'] as String? ??
              tokensMap['token'] as String?;
          refreshToken =
              tokensMap['refresh'] as String? ??
              tokensMap['refresh_token'] as String?;
        } else if (raw['tokens'] is Map) {
          final tokensMap = raw['tokens'] as Map<String, dynamic>;
          accessToken =
              tokensMap['access'] as String? ??
              tokensMap['access_token'] as String? ??
              tokensMap['token'] as String?;
          refreshToken =
              tokensMap['refresh'] as String? ??
              tokensMap['refresh_token'] as String?;
        } else {
          accessToken =
              data['token'] as String? ??
              data['access_token'] as String? ??
              raw['token'] as String?;
          refreshToken =
              data['refresh_token'] as String? ??
              raw['refresh_token'] as String?;
        }

        if (accessToken != null && accessToken.isNotEmpty) {
          await _apiService.tokenManager.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          await _apiService.tokenManager.saveUserRole(UserRole.user.name);
          FcmService.sendFcmTokenToBackend();
        }

        return true;
      }
      return false;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnexpectedException(message: 'Failed to complete profile: $e');
    }
  }

  @override
  Future<bool> agentLogin({
    required String username,
    required String password,
    String? fcmToken,
  }) async {
    try {
      final effectiveFcmToken =
          fcmToken ??
          await FcmService.getFcmToken() ??
          await _apiService.tokenManager.getFcmToken();

      final requestData = <String, dynamic>{
        'username': username.trim(),
        'password': password,
        if (effectiveFcmToken != null && effectiveFcmToken.isNotEmpty)
          'fcm_token': effectiveFcmToken,
      };

      final response = await _apiService.post(
        ApiConstants.agentLogin,
        data: requestData,
        requiresAuth: false,
      );

      if (response.rawData is Map && response.rawData['success'] == false) {
        final errorMsg =
            response.rawData['message']?.toString() ??
            response.message ??
            'Listener login failed';
        throw BadRequestException(
          message: errorMsg,
          statusCode: response.statusCode,
        );
      }

      if (response.isSuccess && response.rawData is Map) {
        final rawMap = response.rawData as Map<String, dynamic>;
        final data = rawMap['data'] is Map<String, dynamic>
            ? rawMap['data'] as Map<String, dynamic>
            : rawMap;

        final tokens = data['tokens'] is Map<String, dynamic>
            ? data['tokens'] as Map<String, dynamic>
            : (rawMap['tokens'] is Map<String, dynamic>
                  ? rawMap['tokens'] as Map<String, dynamic>
                  : null);

        final token =
            tokens?['access'] as String? ??
            tokens?['access_token'] as String? ??
            tokens?['token'] as String? ??
            data['access'] as String? ??
            data['token'] as String? ??
            data['access_token'] as String? ??
            data['key'] as String? ??
            rawMap['token'] as String? ??
            rawMap['access'] as String? ??
            rawMap['access_token'] as String? ??
            rawMap['key'] as String?;

        final refreshToken =
            tokens?['refresh'] as String? ??
            tokens?['refresh_token'] as String? ??
            data['refresh'] as String? ??
            data['refresh_token'] as String? ??
            rawMap['refresh'] as String? ??
            rawMap['refresh_token'] as String?;

        if (token != null && token.isNotEmpty) {
          _verificationToken = token;
          await _apiService.tokenManager.saveTokens(
            accessToken: token,
            refreshToken: refreshToken,
          );
          if (_apiService.tokenManager is TokenManager) {
            await (_apiService.tokenManager as TokenManager)
                .saveVerificationToken(token);
          }
        }

        _currentRole = UserRole.agent;
        await _apiService.tokenManager.saveUserRole(UserRole.agent.name);
        FcmService.sendFcmTokenToBackend();

        final userMap = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : (rawMap['user'] is Map<String, dynamic>
                  ? rawMap['user'] as Map<String, dynamic>
                  : (data['agent'] is Map<String, dynamic>
                        ? data['agent'] as Map<String, dynamic>
                        : null));

        if (userMap != null) {
          _currentUser = UserProfile(
            id: userMap['id']?.toString(),
            userId: userMap['id']?.toString(),
            firstName:
                userMap['display_name']?.toString() ??
                userMap['name']?.toString() ??
                userMap['first_name']?.toString() ??
                userMap['username']?.toString() ??
                userMap['listener_id']?.toString() ??
                username.trim(),
            language: userMap['language']?.toString(),
            isOnline: userMap['is_available'] == true,
          );
          await _apiService.tokenManager.saveUserData(jsonEncode(userMap));
        } else {
          _currentUser = UserProfile(
            firstName: username.trim(),
            isOnline: true,
          );
          await _apiService.tokenManager.saveUserData(
            jsonEncode({
              'username': username.trim(),
              'listener_id': username.trim(),
              'is_available': true,
            }),
          );
        }

        return true;
      }
      return false;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw UnexpectedException(message: 'Agent login failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final role = currentRole;
      final endpoint = (role == UserRole.agent)
          ? ApiConstants.listenerLogout
          : ApiConstants.logout;
      final refreshToken = await _apiService.tokenManager.getRefreshToken();
      await _apiService.post(
        endpoint,
        data: {
          if (refreshToken != null && refreshToken.isNotEmpty)
            'refresh': refreshToken,
        },
        requiresAuth: true,
      );
    } catch (e) {
      // Proceed to clear local tokens even if server call fails
    } finally {
      _currentUser = null;
      _currentRole = null;
      _verificationToken = null;
      await _apiService.tokenManager.clearTokens();
    }
  }
}
