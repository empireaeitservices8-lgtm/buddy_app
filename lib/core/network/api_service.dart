import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../navigation/navigation_service.dart';
import 'api_exceptions.dart';
import 'api_response.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/pretty_logging_interceptor.dart';
import 'token_manager.dart';

/// Centralized, production-grade Network & API client using Dio.
///
/// Features:
/// - Generic, type-safe HTTP CRUD operations (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`).
/// - Multipart file uploads and background file downloads with progress streaming.
/// - Automatic JSON deserialization via generic `converter` callback.
/// - Automatic authorization header injection and queued 401 token refresh.
/// - Clean, colorized debugging logs in `kDebugMode`.
/// - Automatic transformation of [DioException] into strongly typed [ApiException] hierarchy.
class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  late final ITokenManager _tokenManager;

  /// Default network timeout durations (45s to accommodate PythonAnywhere cold-starts & latency)
  static const Duration connectTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 45);
  static const Duration sendTimeout = Duration(seconds: 45);

  /// Factory singleton accessor
  factory ApiService({
    String? baseUrl,
    ITokenManager? tokenManager,
    Dio? customDio,
    String? Function()? languageCodeGetter,
  }) {
    _instance ??= ApiService._internal(
      baseUrl: baseUrl,
      tokenManager: tokenManager,
      customDio: customDio,
      languageCodeGetter: languageCodeGetter,
    );
    return _instance!;
  }

  /// Direct instance constructor for Dependency Injection / Testing
  ApiService.withDio(this._dio, [ITokenManager? tokenManager])
    : _tokenManager = tokenManager ?? TokenManager();

  ApiService._internal({
    String? baseUrl,
    ITokenManager? tokenManager,
    Dio? customDio,
    String? Function()? languageCodeGetter,
  }) {
    _tokenManager = tokenManager ?? TokenManager();

    if (customDio != null) {
      _dio = customDio;
    } else {
      final baseOptions = BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      );

      _dio = Dio(baseOptions);

      // Register Interceptors in logical pipeline order:
      // 1. ConnectivityInterceptor (detects offline status)
      // 2. AuthInterceptor (attaches tokens, handles 401 refresh retries)
      // 3. PrettyLoggingInterceptor (logs clean console output in debug mode)
      _dio.interceptors.addAll([
        ConnectivityInterceptor(),
        AuthInterceptor(
          dio: _dio,
          tokenManager: _tokenManager,
          languageCodeGetter: languageCodeGetter,
        ),
        PrettyLoggingInterceptor(
          logHeaders: true,
          logRequestBody: true,
          logResponseBody: true,
        ),
      ]);
    }
  }

  /// Exposes the underlying [Dio] client for advanced configurations
  Dio get client => _dio;

  /// Exposes the underlying [ITokenManager]
  ITokenManager get tokenManager => _tokenManager;

  // ===========================================================================
  // TYPE-SAFE GENERIC HTTP CRUD METHODS
  // ===========================================================================

  /// Sends a `GET` request to [endpoint].
  ///
  /// [converter] is an optional callback to deserialize the JSON payload into type [T].
  /// [requiresAuth] toggles whether the Bearer token should be attached to this request.
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic json)? converter,
    bool requiresAuth = true,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      return ApiResponse<T>.fromResponse(response, converter: converter);
    } on DioException catch (e) {
      throw _handleDioError(e, requiresAuth: requiresAuth);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnexpectedException(message: e.toString());
    }
  }

  /// Sends a `POST` request to [endpoint] with optional [data] payload.
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic json)? converter,
    bool requiresAuth = true,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return ApiResponse<T>.fromResponse(response, converter: converter);
    } on DioException catch (e) {
      throw _handleDioError(e, requiresAuth: requiresAuth);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnexpectedException(message: e.toString());
    }
  }

  /// Sends a `PUT` request to [endpoint] with [data] payload.
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic json)? converter,
    bool requiresAuth = true,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return ApiResponse<T>.fromResponse(response, converter: converter);
    } on DioException catch (e) {
      throw _handleDioError(e, requiresAuth: requiresAuth);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnexpectedException(message: e.toString());
    }
  }

  /// Sends a `PATCH` request to [endpoint] with partial [data] payload.
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic json)? converter,
    bool requiresAuth = true,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      final response = await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return ApiResponse<T>.fromResponse(response, converter: converter);
    } on DioException catch (e) {
      throw _handleDioError(e, requiresAuth: requiresAuth);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnexpectedException(message: e.toString());
    }
  }

  /// Sends a `DELETE` request to [endpoint].
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic json)? converter,
    bool requiresAuth = true,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
      );

      return ApiResponse<T>.fromResponse(response, converter: converter);
    } on DioException catch (e) {
      throw _handleDioError(e, requiresAuth: requiresAuth);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnexpectedException(message: e.toString());
    }
  }

  // ===========================================================================
  // MULTIPART FILE UPLOADS & FILE DOWNLOADS
  // ===========================================================================

  /// Uploads a multipart [FormData] to [endpoint] with real-time progress callbacks.
  Future<ApiResponse<T>> uploadMultipart<T>(
    String endpoint, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic json)? converter,
    bool requiresAuth = true,
  }) async {
    try {
      final uploadOptions = (options ?? Options()).copyWith(
        headers: {...?options?.headers, 'Content-Type': 'multipart/form-data'},
      );
      final requestOptions = _buildOptions(uploadOptions, requiresAuth);

      final response = await _dio.post(
        endpoint,
        data: formData,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return ApiResponse<T>.fromResponse(response, converter: converter);
    } on DioException catch (e) {
      throw _handleDioError(e, requiresAuth: requiresAuth);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnexpectedException(message: e.toString());
    }
  }

  /// Downloads a remote file from [urlPath] and writes it to [savePath].
  Future<Response> downloadFile(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    bool deleteOnError = true,
    bool requiresAuth = true,
  }) async {
    try {
      final requestOptions = _buildOptions(options, requiresAuth);
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: requestOptions,
        deleteOnError: deleteOnError,
      );
    } on DioException catch (e) {
      throw _handleDioError(e, requiresAuth: requiresAuth);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnexpectedException(message: e.toString());
    }
  }

  // ===========================================================================
  // PRIVATE HELPERS
  // ===========================================================================

  /// Centralized exception handler ensuring unauthenticated 401 triggers redirect to Splash screen.
  ApiException _handleDioError(DioException e, {bool requiresAuth = true}) {
    final exception = ApiException.fromDioException(e);
    if (exception is UnauthorizedException && requiresAuth) {
      final path = e.requestOptions.path.toLowerCase();
      final isAuthEndpoint = !requiresAuth ||
          path.contains('login') ||
          path.contains('auth/') ||
          path.contains('refresh') ||
          path.contains('logout') ||
          path.contains('verify-otp') ||
          path.contains('send-otp') ||
          path.contains('complete-profile');
      if (!isAuthEndpoint) {
        NavigationService.navigateToSplash(reason: 'Session expired. Please log in again.');
      }
    }
    return exception;
  }

  /// Injects custom extra flags such as `requires_auth` into [Options].
  Options _buildOptions(Options? options, bool requiresAuth) {
    final effectiveOptions = options ?? Options();
    final extra = Map<String, dynamic>.from(effectiveOptions.extra ?? {});
    extra['requires_auth'] = requiresAuth;
    return effectiveOptions.copyWith(extra: extra);
  }
}
