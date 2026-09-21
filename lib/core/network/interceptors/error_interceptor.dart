import 'package:dio/dio.dart';
import '../api_exceptions.dart';

/// Interceptor to normalize and log network errors
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Transform DioException into ApiException for standard access
    final apiException = ApiException.fromDioException(err);

    // Attach mapped exception to request extra so repositories can retrieve it cleanly
    err.requestOptions.extra['api_exception'] = apiException;

    return handler.next(err);
  }
}
