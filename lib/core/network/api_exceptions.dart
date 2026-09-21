import 'dart:io';
import 'package:dio/dio.dart';

/// Base custom exception for all network, HTTP, and API errors in the application.
abstract class ApiException implements Exception {
  /// User-friendly error message or backend error description.
  final String message;

  /// HTTP status code (if available, e.g. 400, 401, 404, 500).
  final int? statusCode;

  /// Raw response payload returned by the server.
  final dynamic data;

  /// Structured field-level validation errors (e.g. `{"email": ["Invalid format"]}`).
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.errors,
  });

  /// Factory mapper to convert a [DioException] into a strongly-typed [ApiException].
  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Connection timed out. Please check your internet connection and try again.',
          statusCode: error.response?.statusCode,
          data: error.response?.data,
        );

      case DioExceptionType.badCertificate:
        return const SecurityException(
          message: 'SSL certificate verification failed. Untrusted server connection.',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);

      case DioExceptionType.cancel:
        return const RequestCancelledException(
          message: 'The network request was cancelled.',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection detected. Please verify your WiFi or mobile network.',
        );

      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException ||
            (error.message != null && error.message!.contains('SocketException'))) {
          return const NetworkException(
            message: 'Unable to connect to the server. Please check your internet connection.',
          );
        }
        return UnexpectedException(
          message: error.message ?? 'An unexpected network error occurred. Please try again.',
          statusCode: error.response?.statusCode,
          data: error.response?.data,
        );
    }
  }

  /// Maps HTTP response status codes into specific [ApiException] subclasses.
  static ApiException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode ?? 500;
    final responseData = response?.data;
    final extractedMessage = _extractErrorMessage(responseData);
    final extractedErrors = _extractValidationErrors(responseData);

    switch (statusCode) {
      case 400:
        if (extractedErrors != null && extractedErrors.isNotEmpty) {
          return ValidationException(
            message: extractedMessage ?? 'Invalid input data. Please verify your inputs.',
            statusCode: statusCode,
            errors: extractedErrors,
            data: responseData,
          );
        }
        return BadRequestException(
          message: extractedMessage ?? 'Bad request. Please check the submitted data.',
          statusCode: statusCode,
          data: responseData,
        );

      case 401:
        return UnauthorizedException(
          message: extractedMessage ?? 'Session expired or unauthenticated. Please log in again.',
          statusCode: statusCode,
          data: responseData,
        );

      case 403:
        return ForbiddenException(
          message: extractedMessage ?? 'You do not have permission to access this resource.',
          statusCode: statusCode,
          data: responseData,
        );

      case 404:
        return NotFoundException(
          message: extractedMessage ?? 'The requested resource was not found on the server.',
          statusCode: statusCode,
          data: responseData,
        );

      case 409:
        return ConflictException(
          message: extractedMessage ?? 'A state conflict occurred. The resource might already exist.',
          statusCode: statusCode,
          data: responseData,
        );

      case 422:
        return ValidationException(
          message: extractedMessage ?? 'Validation failed. Please correct the highlighted fields.',
          statusCode: statusCode,
          errors: extractedErrors,
          data: responseData,
        );

      case 429:
        return RateLimitException(
          message: extractedMessage ?? 'Too many requests. Please slow down and wait a moment.',
          statusCode: statusCode,
          data: responseData,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: extractedMessage ?? 'Server error. Please try again later.',
          statusCode: statusCode,
          data: responseData,
        );

      default:
        return UnexpectedException(
          message: extractedMessage ?? 'Something went wrong. Please try again.',
          statusCode: statusCode,
          data: responseData,
        );
    }
  }

  /// Extracts human-readable error messages from standard backend formats
  /// (e.g. Django Rest Framework, FastAPI, Express, Laravel, Spring Boot).
  static String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      if (data.trim().startsWith('<')) {
        // Raw HTML error page from server / proxy
        return null;
      }
      return data;
    }
    if (data is Map) {
      if (data.containsKey('message') && data['message'] is String) {
        return data['message'] as String;
      }
      if (data.containsKey('detail') && data['detail'] is String) {
        return data['detail'] as String;
      }
      if (data.containsKey('error') && data['error'] is String) {
        return data['error'] as String;
      }
      if (data.containsKey('non_field_errors') && data['non_field_errors'] is List) {
        return (data['non_field_errors'] as List).join(', ');
      }
      // Check if top-level dictionary contains validation arrays
      for (final entry in data.entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          final firstVal = (entry.value as List).first;
          return '${entry.key}: $firstVal';
        }
        if (entry.value is String && entry.key != 'status' && entry.key != 'code') {
          return '${entry.key}: ${entry.value}';
        }
      }
    }
    return null;
  }

  /// Extracts structured validation field errors (field -> List of messages or nested map).
  static Map<String, dynamic>? _extractValidationErrors(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('errors') && data['errors'] is Map<String, dynamic>) {
        return data['errors'] as Map<String, dynamic>;
      }
      if (data.containsKey('errors') && data['errors'] is List) {
        return {'general': data['errors']};
      }
      // Inspect if map keys point to field error arrays/strings
      final fieldErrors = <String, dynamic>{};
      for (final entry in data.entries) {
        if (entry.key != 'message' &&
            entry.key != 'status' &&
            entry.key != 'statusCode' &&
            entry.key != 'success') {
          fieldErrors[entry.key] = entry.value;
        }
      }
      if (fieldErrors.isNotEmpty) {
        return fieldErrors;
      }
    }
    return null;
  }

  @override
  String toString() => message;
}

/// 400 Bad Request Exception
class BadRequestException extends ApiException {
  const BadRequestException({
    required super.message,
    super.statusCode = 400,
    super.data,
  });
}

/// 401 Unauthorized / Token Expired Exception
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    required super.message,
    super.statusCode = 401,
    super.data,
  });
}

/// 403 Forbidden Access Exception
class ForbiddenException extends ApiException {
  const ForbiddenException({
    required super.message,
    super.statusCode = 403,
    super.data,
  });
}

/// 404 Not Found Exception
class NotFoundException extends ApiException {
  const NotFoundException({
    required super.message,
    super.statusCode = 404,
    super.data,
  });
}

/// 409 Conflict Exception (resource already exists or concurrent edit)
class ConflictException extends ApiException {
  const ConflictException({
    required super.message,
    super.statusCode = 409,
    super.data,
  });
}

/// 422 / 400 Validation Error with field-level errors map
class ValidationException extends ApiException {
  const ValidationException({
    required super.message,
    super.statusCode = 422,
    super.errors,
    super.data,
  });

  /// Helper to get the first validation error message for a specific field.
  String? getFieldError(String fieldName) {
    if (errors == null || !errors!.containsKey(fieldName)) return null;
    final fieldVal = errors![fieldName];
    if (fieldVal is List && fieldVal.isNotEmpty) {
      return fieldVal.first.toString();
    }
    return fieldVal?.toString();
  }
}

/// 429 Rate Limit Exceeded Exception
class RateLimitException extends ApiException {
  const RateLimitException({
    required super.message,
    super.statusCode = 429,
    super.data,
  });
}

/// 500+ Internal Server / Gateway Exception
class ServerException extends ApiException {
  const ServerException({
    required super.message,
    super.statusCode = 500,
    super.data,
  });
}

/// Offline / No Internet Connection Exception
class NetworkException extends ApiException {
  const NetworkException({
    required super.message,
    super.statusCode,
  });
}

/// Request Timeout (Connect / Send / Receive) Exception
class TimeoutException extends ApiException {
  const TimeoutException({
    required super.message,
    super.statusCode,
    super.data,
  });
}

/// Cancelled Request Exception
class RequestCancelledException extends ApiException {
  const RequestCancelledException({
    required super.message,
    super.statusCode,
  });
}

/// SSL / Bad Certificate Exception
class SecurityException extends ApiException {
  const SecurityException({
    required super.message,
  });
}

/// Unexpected / Unknown Network Exception
class UnexpectedException extends ApiException {
  const UnexpectedException({
    required super.message,
    super.statusCode,
    super.data,
  });
}
