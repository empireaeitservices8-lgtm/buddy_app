import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract contract for managing authentication tokens
abstract class ITokenManager {
  FutureOr<String?> getAccessToken();
  FutureOr<String?> getRefreshToken();
  Future<void> saveTokens({required String accessToken, String? refreshToken});
  Future<void> clearTokens();
  FutureOr<bool> hasToken();
  Future<void> saveUserData(String userDataJson);
  Future<String?> getUserData();
  Future<void> saveUserRole(String role);
  Future<String?> getUserRole();
  Future<void> saveVerificationToken(String token);
  Future<String?> getVerificationToken();
  Future<void> saveFcmToken(String token);
  Future<String?> getFcmToken();
}

/// SharedPreferences-backed Token Manager implementation
class TokenManager implements ITokenManager {
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyVerificationToken = 'auth_verification_token';
  static const String _keyUserData = 'auth_user_data';
  static const String _keyUserRole = 'auth_user_role';
  static const String _keyFcmToken = 'fcm_device_token';

  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  String? _accessToken;
  String? _refreshToken;
  String? _verificationToken;
  String? _userRole;
  String? _userData;
  String? _fcmToken;
  bool _isInitialized = false;

  final StreamController<bool> _authStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get authStatusStream => _authStatusController.stream;

  String? get userRoleSync => _userRole;
  String? get userDataSync => _userData;
  String? get fcmTokenSync => _fcmToken;

  /// Ensure tokens are loaded from SharedPreferences on app startup
  Future<void> init() async {
    if (_isInitialized && _accessToken != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken =
          prefs.getString(_keyAccessToken) ??
          prefs.getString('access_token') ??
          prefs.getString('token') ??
          prefs.getString('access');
      _refreshToken =
          prefs.getString(_keyRefreshToken) ??
          prefs.getString('refresh_token') ??
          prefs.getString('refresh');
      _verificationToken =
          prefs.getString(_keyVerificationToken) ??
          prefs.getString('verification_token');
      _userRole = prefs.getString(_keyUserRole);
      _userData = prefs.getString(_keyUserData);
      _fcmToken =
          prefs.getString(_keyFcmToken) ??
          prefs.getString('fcm_token') ??
          prefs.getString('device_token');

      // Auto-fallback: If role isn't explicitly set, detect from saved userData JSON
      if (_userRole == null && _userData != null && _userData!.isNotEmpty) {
        if (_userData!.contains('"role":"AGENT"') ||
            _userData!.contains('"role":"agent"') ||
            _userData!.contains('"role":"LISTENER"') ||
            _userData!.contains('"role":"listener"') ||
            _userData!.contains('"is_agent":true')) {
          _userRole = 'agent';
        } else {
          _userRole = 'user';
        }
      }

      _isInitialized = true;
    } catch (_) {
      _isInitialized = true;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken =
        prefs.getString(_keyAccessToken) ??
        prefs.getString('access_token') ??
        prefs.getString('token') ??
        prefs.getString('access');
    _isInitialized = true;
    return _accessToken;
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    _refreshToken =
        prefs.getString(_keyRefreshToken) ??
        prefs.getString('refresh_token') ??
        prefs.getString('refresh');
    _isInitialized = true;
    return _refreshToken;
  }

  @override
  Future<String?> getVerificationToken() async {
    final prefs = await SharedPreferences.getInstance();
    _verificationToken =
        prefs.getString(_keyVerificationToken) ??
        prefs.getString('verification_token') ??
        _accessToken ??
        prefs.getString(_keyAccessToken) ??
        prefs.getString('access_token') ??
        prefs.getString('token') ??
        prefs.getString('access');
    return _verificationToken;
  }

  @override
  Future<void> saveVerificationToken(String token) async {
    _verificationToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyVerificationToken, token);
    } catch (_) {}
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _accessToken = accessToken;
    if (refreshToken != null) {
      _refreshToken = refreshToken;
    }
    _isInitialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, accessToken);
      if (refreshToken != null) {
        await prefs.setString(_keyRefreshToken, refreshToken);
      }
    } catch (_) {}

    debugPrint('🔑 [TokenManager] Active Bearer Token: Bearer $accessToken');
    _authStatusController.add(true);
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _verificationToken = null;
    _userRole = null;
    _userData = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      const keysToRemove = [
        _keyAccessToken,
        'access_token',
        'token',
        'access',
        _keyRefreshToken,
        'refresh_token',
        'refresh',
        _keyVerificationToken,
        'verification_token',
        _keyUserData,
        'user_data',
        'user',
        _keyUserRole,
        'user_role',
        'role',
        'agent_token',
        'listener_token',
      ];
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
    } catch (_) {}

    _authStatusController.add(false);
  }

  @override
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> saveUserData(String userDataJson) async {
    _userData = userDataJson;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserData, userDataJson);
    } catch (_) {}
  }

  @override
  Future<String?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userData = prefs.getString(_keyUserData);
      return _userData;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUserRole(String role) async {
    _userRole = role;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserRole, role);
    } catch (_) {}
  }

  @override
  Future<String?> getUserRole() async {
    if (_userRole != null && _userRole!.isNotEmpty) return _userRole;
    try {
      final prefs = await SharedPreferences.getInstance();
      _userRole = prefs.getString(_keyUserRole);
      if (_userRole != null && _userRole!.isNotEmpty) return _userRole;

      // Fallback inspection of user data only if role not explicitly set
      final userDataStr = prefs.getString(_keyUserData);
      if (userDataStr != null && userDataStr.isNotEmpty) {
        if (userDataStr.contains('"role":"AGENT"') ||
            userDataStr.contains('"role":"agent"') ||
            userDataStr.contains('"role":"LISTENER"') ||
            userDataStr.contains('"role":"listener"') ||
            userDataStr.contains('"is_agent":true')) {
          _userRole = 'agent';
          return 'agent';
        }
      }
      _userRole = 'user';
      return 'user';
    } catch (_) {
      return _userRole ?? 'user';
    }
  }

  @override
  Future<void> saveFcmToken(String token) async {
    _fcmToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFcmToken, token);
    } catch (_) {}
  }

  @override
  Future<String?> getFcmToken() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) return _fcmToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      _fcmToken =
          prefs.getString(_keyFcmToken) ??
          prefs.getString('fcm_token') ??
          prefs.getString('device_token');
      return _fcmToken;
    } catch (_) {
      return _fcmToken;
    }
  }

  void dispose() {
    _authStatusController.close();
  }
}
