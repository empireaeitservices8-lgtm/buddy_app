import 'package:dio/dio.dart';

/// Generic response wrapper for type-safe API communication.
///
/// Encapsulates parsed data [T], HTTP [statusCode], [message], [headers],
/// and raw body [rawData].
class ApiResponse<T> {
  /// Parsed model or primitive data instance of type [T].
  final T? data;

  /// HTTP status code from server (e.g. 200, 201).
  final int statusCode;

  /// Optional message returned by server or client.
  final String? message;

  /// Whether the HTTP status code falls in the 2xx success range (200-299).
  final bool isSuccess;

  /// Response headers returned by server.
  final Headers? headers;

  /// Raw unstructured response payload from [Dio].
  final dynamic rawData;

  const ApiResponse({
    this.data,
    required this.statusCode,
    this.message,
    required this.isSuccess,
    this.headers,
    this.rawData,
  });

  /// Factory constructor to parse standard [Response] into strongly-typed [ApiResponse<T>].
  factory ApiResponse.fromResponse(
    Response response, {
    T Function(dynamic json)? converter,
  }) {
    final status = response.statusCode ?? 200;
    final isSuccessful = status >= 200 && status < 300;
    final body = response.data;

    T? parsedData;
    String? msg;

    if (body is Map<String, dynamic>) {
      if (body.containsKey('message') && body['message'] is String) {
        msg = body['message'] as String;
      } else if (body.containsKey('detail') && body['detail'] is String) {
        msg = body['detail'] as String;
      }
    }

    if (converter != null && body != null) {
      // Check if data payload is nested inside standard envelope keys ("data" or "results")
      if (body is Map<String, dynamic> && body.containsKey('data') && body['data'] != null) {
        try {
          parsedData = converter(body['data']);
        } catch (_) {
          // If inner conversion fails, try root object
          parsedData = converter(body);
        }
      } else {
        parsedData = converter(body);
      }
    } else if (body is T) {
      parsedData = body;
    }

    return ApiResponse<T>(
      data: parsedData,
      statusCode: status,
      message: msg,
      isSuccess: isSuccessful,
      headers: response.headers,
      rawData: body,
    );
  }

  /// Convenience getter to check whether the response carries a non-null payload.
  bool get hasData => data != null;

  @override
  String toString() =>
      'ApiResponse<$T>(statusCode: $statusCode, isSuccess: $isSuccess, message: $message, hasData: $hasData)';
}
