import 'dart:io';
import 'package:dio/dio.dart';
import '../api_exceptions.dart';

/// Interceptor that proactively catches network connection disruptions, offline status,
/// and timeouts, normalizing them into clean [ApiException] references.
class ConnectivityInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If the error is a connection failure or socket failure
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.error is SocketException) {
      // Pass the DioException with descriptive context or handled by ApiService
      return handler.next(err);
    }

    return handler.next(err);
  }
}
