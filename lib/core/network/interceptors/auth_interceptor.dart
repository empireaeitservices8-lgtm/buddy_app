import 'dart:async';
import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../../navigation/navigation_service.dart';
import '../../services/fcm_service.dart';
import '../token_manager.dart';

/// Interceptor that automatically attaches authorization tokens and standard headers,
/// and handles automatic token refreshing upon encountering HTTP 401 Unauthorized errors.
class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final ITokenManager _tokenManager;
  final String? Function()? _languageCodeGetter;
  final Map<String, String>? _customHeaders;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor({
    required Dio dio,
    required ITokenManager tokenManager,
    String? Function()? languageCodeGetter,
    Map<String, String>? customHeaders,
  }) : _dio = dio,
       _tokenManager = tokenManager,
       _languageCodeGetter = languageCodeGetter,
       _customHeaders = customHeaders;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Attach authorization bearer token if available and not explicitly disabled
    final requiresAuth = options.extra['requires_auth'] as bool? ?? true;
    if (requiresAuth) {
      final token = await _tokenManager.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // 2. Attach default content headers
    options.headers['Accept'] = 'application/json';
    if (!options.headers.containsKey('Content-Type') &&
        options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }

    // 3. Attach localization & platform metadata headers
    final lang = _languageCodeGetter?.call() ?? 'en';
    options.headers['Accept-Language'] = lang;
    options.headers['X-Client-Platform'] = 'flutter';

    // 4. Attach any user-specified custom headers
    if (_customHeaders != null) {
      options.headers.addAll(_customHeaders);
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final responseStr = err.response?.data?.toString().toLowerCase() ?? '';
    final messageStr = err.message?.toLowerCase() ?? '';

    // Check if Firebase rejected FCM token with NotRegistered error
    if (responseStr.contains('notregistered') ||
        responseStr.contains('not_registered') ||
        responseStr.contains('invalidregistration') ||
        messageStr.contains('notregistered') ||
        messageStr.contains('not_registered')) {
      FcmService.refreshAndSyncToken(forceNew: true);
    }
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path.toLowerCase();
    final requiresAuth = err.requestOptions.extra['requires_auth'] as bool? ?? true;

    // Check if the failed request is an auth endpoint or does not require auth to prevent infinite loops and false redirects
    final isAuthEndpoint = !requiresAuth ||
        path.contains('login') ||
        path.contains('auth/') ||
        path.contains('refresh') ||
        path.contains('logout') ||
        path.contains('verify-otp') ||
        path.contains('send-otp') ||
        path.contains('complete-profile');

    final isUnauthorized = statusCode == 401;

    if (isUnauthorized && !isAuthEndpoint) {
      final retryCount = err.requestOptions.extra['retry_count'] as int? ?? 0;
      if (retryCount >= 1) {
        // Already attempted retry once; abort, purge authentication state, and navigate to splash
        await _tokenManager.clearTokens();
        NavigationService.navigateToSplash(
          reason: 'Session expired. Please log in again.',
        );
        return handler.next(err);
      }

      try {
        final newToken = await _performTokenRefresh();
        if (newToken != null && newToken.isNotEmpty) {
          // Clone request options and re-dispatch with updated token
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newToken';
          requestOptions.extra['retry_count'] = retryCount + 1;

          final response = await _dio.fetch(requestOptions);
          return handler.resolve(response);
        } else {
          // Token refresh returned null / expired refresh token
          await _tokenManager.clearTokens();
          NavigationService.navigateToSplash(
            reason: 'Session expired. Please log in again.',
          );
          return handler.next(err);
        }
      } catch (e) {
        await _tokenManager.clearTokens();
        NavigationService.navigateToSplash(
          reason: 'Session expired. Please log in again.',
        );
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  /// Thread-safe token refresh mechanism using a singleton Completer lock.
  /// Subsequent requests wait on the same Future until refreshed.
  Future<String?> _performTokenRefresh() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _isRefreshing = false;
        _refreshCompleter?.complete(null);
        return null;
      }

      // Use a clean, isolated Dio instance without this interceptor to avoid cycles
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        'auth/refresh-token/',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final newAccessToken = data is Map
            ? (data['access_token'] ?? data['token']) as String?
            : null;
        final newRefreshToken = data is Map
            ? data['refresh_token'] as String?
            : null;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await _tokenManager.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken ?? refreshToken,
          );
          _isRefreshing = false;
          _refreshCompleter?.complete(newAccessToken);
          return newAccessToken;
        }
      }

      _isRefreshing = false;
      _refreshCompleter?.complete(null);
      return null;
    } catch (e) {
      _isRefreshing = false;
      _refreshCompleter?.complete(null);
      return null;
    }
  }
}
